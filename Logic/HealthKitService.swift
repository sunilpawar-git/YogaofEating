import Foundation
import HealthKit
import OSLog

private let healthKitLogger = Logger(subsystem: "com.yogaofeating", category: "HealthKit")

/// Protocol for reading body metrics from HealthKit.
/// Enables injection of a test double in place of `HealthKitService.shared`.
@MainActor
protocol HealthKitBodyMetricsProviding {
    func requestAuthorization() async throws -> Bool
    func fetchLatestWeight(unit: HKUnit) async throws -> Double?
    func fetchLatestHeight(unit: HKUnit) async throws -> Double?
    func fetchAge() throws -> Int?
    func fetchGender() throws -> Int?
}

/// Service to handle HealthKit interactions for reading body metrics.
/// `@MainActor` ensures all mutable state (sleepDataCache, enableSleepLogging) is accessed
/// from a single actor, preventing data races from concurrent HealthKit callbacks.
@MainActor
class HealthKitService {
    static let shared = HealthKitService()

    let healthStore: HKHealthStore?

    /// Enable debug logging for sleep data processing
    var enableSleepLogging = true

    /// Handles caching and in-flight query coalescing so concurrent callers never fire
    /// more than one HealthKit round-trip for the same date.
    let sleepCoalescer = HealthKitSleepCoalescer()

    private init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        } else {
            self.healthStore = nil
        }
    }

    // MARK: - Authorization

    /// Requests authorization to read body metrics from HealthKit.
    func requestAuthorization() async throws -> Bool {
        guard let healthStore else {
            throw HealthKitError.notAvailable
        }

        let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
            .bodyMass, .height, .activeEnergyBurned, .basalEnergyBurned
        ]
        let characteristicIdentifiers: [HKCharacteristicTypeIdentifier] = [
            .dateOfBirth, .biologicalSex
        ]

        var typesToRead = Set<HKObjectType>()
        for id in quantityIdentifiers {
            guard let type = HKObjectType.quantityType(forIdentifier: id) else {
                throw HealthKitError.notAvailable
            }
            typesToRead.insert(type)
        }
        for id in characteristicIdentifiers {
            guard let type = HKObjectType.characteristicType(forIdentifier: id) else {
                throw HealthKitError.notAvailable
            }
            typesToRead.insert(type)
        }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.notAvailable
        }
        typesToRead.insert(sleepType)

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        return true
    }

    // MARK: - Body Metrics

    /// Fetches the latest body weight from HealthKit in the specified unit.
    func fetchLatestWeight(unit: HKUnit) async throws -> Double? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        return try await self.fetchLatestQuantity(for: weightType, unit: unit)
    }

    /// Fetches the latest height from HealthKit in the specified unit.
    func fetchLatestHeight(unit: HKUnit) async throws -> Double? {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else { return nil }
        return try await self.fetchLatestQuantity(for: heightType, unit: unit)
    }

    /// Fetches birth date and calculates age.
    func fetchAge() throws -> Int? {
        guard let healthStore else { return nil }
        let components = try healthStore.dateOfBirthComponents()
        guard let birthDate = components.date else { return nil }

        let ageComponents = Calendar.current.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year
    }

    /// Fetches biological sex and maps to the app's Gender raw value (Int).
    func fetchGender() throws -> Int? {
        guard let healthStore else { return nil }
        let sex = try healthStore.biologicalSex().biologicalSex
        switch sex {
        case .male: return 1
        case .female: return 2
        case .other: return 3
        default: return 0
        }
    }

    private func fetchLatestQuantity(for type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        guard let healthStore else { return nil }

        // Limit scan to the last 90 days — avoids a full historical table scan
        // that would scan potentially years of data for a single "latest" value.
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? .distantPast
        let predicate = HKQuery.predicateForSamples(withStart: ninetyDaysAgo, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Sleep Data

    /// Fetches sleep analysis data for a specific date (last night's sleep).
    /// Results are cached for 5 minutes. Concurrent callers for the same date
    /// share a single in-flight HealthKit query via `sleepCoalescer`.
    /// - Parameter date: The date to fetch sleep data for (defaults to today)
    /// - Returns: Sleep data including duration, time in bed, and quality score
    func fetchSleepData(for date: Date = Date()) async throws -> SleepData? {
        guard let healthStore else { return nil }
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        if self.enableSleepLogging, let age = self.sleepCoalescer.cacheAge(for: date) {
            healthKitLogger.debug("Sleep data served from cache (age: \(Int(age), privacy: .private)s)")
        }

        return try await self.sleepCoalescer.fetch(for: date) { [weak self] in
            guard let self else { return nil }
            return try await self.executeRawSleepQuery(
                healthStore: healthStore,
                sleepType: sleepType,
                for: date
            )
        }
    }

    private func executeRawSleepQuery(
        healthStore: HKHealthStore,
        sleepType: HKCategoryType,
        for date: Date
    ) async throws -> SleepData? {
        let (windowStart, windowEnd) = Self.sleepQueryWindow(for: date)

        if self.enableSleepLogging {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, HH:mm"
            healthKitLogger.debug(
                "Sleep query window: \(formatter.string(from: windowStart), privacy: .private) to \(formatter.string(from: windowEnd), privacy: .private)"
            )
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: windowStart,
            end: windowEnd,
            options: .strictStartDate
        )

        // Fetch raw samples on HealthKit's background thread — no main-actor state touched here.
        let rawSamples: [HKCategorySample]? = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKCategorySample])
                }
            }
            healthStore.execute(query)
        }

        // Back on the main actor — safe to access all @MainActor-isolated state.
        guard let samples = rawSamples, !samples.isEmpty else {
            if self.enableSleepLogging {
                healthKitLogger.debug("No sleep samples found in window")
            }
            return nil
        }

        return self.processSamples(samples)
    }

    // MARK: - Private Helpers

    /// Calculates the query window for "last night's sleep".
    /// - Parameter date: The reference date (typically today)
    /// - Returns: Tuple of (start, end) dates for the query
    private static func sleepQueryWindow(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // 6 PM previous day to noon today — use safe fallbacks if calendar arithmetic fails
        guard let windowStart = calendar.date(byAdding: .hour, value: -6, to: startOfDay),
              let windowEnd = calendar.date(byAdding: .hour, value: 12, to: startOfDay)
        else {
            healthKitLogger.error("Failed to compute sleep query window — using fallback (startOfDay ± 0)")
            return (startOfDay, startOfDay)
        }

        return (windowStart, windowEnd)
    }

    /// Processes HKCategorySamples into SleepData.
    private func processSamples(_ samples: [HKCategorySample]) -> SleepData? {
        if self.enableSleepLogging {
            healthKitLogger.debug("Found \(samples.count, privacy: .private) total sleep samples")
        }

        // Group by source and select preferred
        let samplesBySource = Dictionary(grouping: samples) {
            $0.sourceRevision.source.bundleIdentifier
        }

        if self.enableSleepLogging {
            healthKitLogger.debug("Sources found: \(samplesBySource.keys.joined(separator: ", "), privacy: .private)")
        }

        guard let preferredSource = SleepDataProcessor.selectPreferredSource(from: Array(samplesBySource.keys)) else {
            return nil
        }

        if self.enableSleepLogging {
            healthKitLogger.debug("Using preferred source: \(preferredSource, privacy: .private)")
        }

        let sourceSamples = samplesBySource[preferredSource] ?? samples

        if self.enableSleepLogging {
            healthKitLogger.debug("Processing \(sourceSamples.count, privacy: .private) samples from preferred source")
        }

        // Convert HKCategorySamples to SleepSampleData
        let sleepSamples = sourceSamples
            .sorted { $0.startDate < $1.startDate }
            .compactMap { self.convertToSleepSampleData($0) }

        // Process using SleepDataProcessor
        return SleepDataProcessor.processSleepSamples(sleepSamples, enableLogging: self.enableSleepLogging)
    }

    /// Converts an HKCategorySample to SleepSampleData.
    private func convertToSleepSampleData(_ sample: HKCategorySample) -> SleepSampleData? {
        let value = sample.value
        let stage: SleepStage

        if value == HKCategoryValueSleepAnalysis.inBed.rawValue {
            stage = .inBed
        } else if value == HKCategoryValueSleepAnalysis.awake.rawValue {
            stage = .awake
        } else if #available(iOS 16.0, *) {
            if value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                stage = .asleepUnspecified
            } else if value == HKCategoryValueSleepAnalysis.asleepCore.rawValue {
                stage = .asleepCore
            } else if value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue {
                stage = .asleepDeep
            } else if value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                stage = .asleepREM
            } else {
                return nil // Unknown value
            }
        } else {
            // iOS < 16: only asleep category
            if value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                stage = .asleepUnspecified
            } else {
                return nil
            }
        }

        return SleepSampleData(
            startDate: sample.startDate,
            endDate: sample.endDate,
            sleepStage: stage
        )
    }

    /// Clears the sleep data cache. Useful for forcing a fresh query or app cleanup.
    func clearSleepCache() {
        self.sleepCoalescer.clearCache()
        if self.enableSleepLogging {
            healthKitLogger.debug("Sleep data cache cleared")
        }
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            "HealthKit is not available on this device"
        }
    }
}

extension HealthKitService: HealthKitBodyMetricsProviding {}
