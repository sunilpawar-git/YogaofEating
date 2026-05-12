import Foundation
import HealthKit
import OSLog

private let healthKitLogger = Logger(subsystem: "com.yogaofeating", category: "HealthKit")

/// Service to handle HealthKit interactions for reading body metrics.
/// `@MainActor` ensures all mutable state (sleepDataCache, enableSleepLogging) is accessed
/// from a single actor, preventing data races from concurrent HealthKit callbacks.
@MainActor
class HealthKitService {
    static let shared = HealthKitService()

    let healthStore: HKHealthStore?

    /// Enable debug logging for sleep data processing
    var enableSleepLogging = true

    /// Cache for sleep data queries to prevent redundant HealthKit lookups.
    /// Key: normalized date (start of day), Value: (cached SleepData, timestamp)
    private var sleepDataCache: [Date: (data: SleepData?, timestamp: Date)] = [:]

    /// Cache expiration interval. Sleep data from the same date won't be re-queried within this window.
    private let sleepCacheExpiration: TimeInterval = TimingConstants.sleepCacheDuration

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
    /// Results are cached for 5 minutes to avoid redundant HealthKit queries.
    /// - Parameter date: The date to fetch sleep data for (defaults to today)
    /// - Returns: Sleep data including duration, time in bed, and quality score
    func fetchSleepData(for date: Date = Date()) async throws -> SleepData? {
        guard let healthStore else { return nil }
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        // Check cache first
        if let cached = self.sleepDataCache[normalizedDate] {
            let timeSinceCached = Date().timeIntervalSince(cached.timestamp)
            if timeSinceCached < self.sleepCacheExpiration {
                if self.enableSleepLogging {
                    healthKitLogger.debug(
                        "Sleep data served from cache (age: \(Int(timeSinceCached), privacy: .public)s)"
                    )
                }
                return cached.data
            } else {
                // Cache expired, remove it
                self.sleepDataCache.removeValue(forKey: normalizedDate)
            }
        }

        let (windowStart, windowEnd) = Self.sleepQueryWindow(for: date)

        if self.enableSleepLogging {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, HH:mm"
            healthKitLogger
                .debug(
                    "Sleep query window: \(formatter.string(from: windowStart), privacy: .public) to \(formatter.string(from: windowEnd), privacy: .public)"
                )
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: windowStart,
            end: windowEnd,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { [weak self] _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    Task { @MainActor [weak self] in
                        if self?.enableSleepLogging == true {
                            healthKitLogger.debug("No sleep samples found in window")
                        }
                        self?.sleepDataCache[normalizedDate] = (nil, Date())
                    }
                    continuation.resume(returning: nil)
                    return
                }

                Task { @MainActor [weak self] in
                    let sleepData = self?.processSamples(samples)
                    self?.sleepDataCache[normalizedDate] = (sleepData, Date())
                    continuation.resume(returning: sleepData)
                }
            }
            healthStore.execute(query)
        }
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
            healthKitLogger.debug("Found \(samples.count, privacy: .public) total sleep samples")
        }

        // Group by source and select preferred
        let samplesBySource = Dictionary(grouping: samples) {
            $0.sourceRevision.source.bundleIdentifier
        }

        if self.enableSleepLogging {
            healthKitLogger.debug("Sources found: \(samplesBySource.keys.joined(separator: ", "), privacy: .public)")
        }

        guard let preferredSource = SleepDataProcessor.selectPreferredSource(from: Array(samplesBySource.keys)) else {
            return nil
        }

        if self.enableSleepLogging {
            healthKitLogger.debug("Using preferred source: \(preferredSource, privacy: .public)")
        }

        let sourceSamples = samplesBySource[preferredSource] ?? samples

        if self.enableSleepLogging {
            healthKitLogger.debug("Processing \(sourceSamples.count, privacy: .public) samples from preferred source")
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
        self.sleepDataCache.removeAll()
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
