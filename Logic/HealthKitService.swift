import Foundation
import HealthKit

/// Service to handle HealthKit interactions for reading body metrics.
class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore: HKHealthStore?

    /// Enable debug logging for sleep data processing
    var enableSleepLogging = true

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

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

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

        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
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
    /// - Parameter date: The date to fetch sleep data for (defaults to today)
    /// - Returns: Sleep data including duration, time in bed, and quality score
    func fetchSleepData(for date: Date = Date()) async throws -> SleepData? {
        guard let healthStore else { return nil }
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let (windowStart, windowEnd) = Self.sleepQueryWindow(for: date)

        if self.enableSleepLogging {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, HH:mm"
            print("🛏️ Query window: \(formatter.string(from: windowStart)) to \(formatter.string(from: windowEnd))")
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
                    if self?.enableSleepLogging == true {
                        print("🛏️ No sleep samples found in window")
                    }
                    continuation.resume(returning: nil)
                    return
                }

                let sleepData = self?.processSamples(samples)
                continuation.resume(returning: sleepData)
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

        // 6 PM previous day to noon today
        let windowStart = calendar.date(byAdding: .hour, value: -6, to: startOfDay)!
        let windowEnd = calendar.date(byAdding: .hour, value: 12, to: startOfDay)!

        return (windowStart, windowEnd)
    }

    /// Processes HKCategorySamples into SleepData.
    private func processSamples(_ samples: [HKCategorySample]) -> SleepData? {
        if self.enableSleepLogging {
            print("🛏️ Found \(samples.count) total sleep samples")
        }

        // Group by source and select preferred
        let samplesBySource = Dictionary(grouping: samples) {
            $0.sourceRevision.source.bundleIdentifier
        }

        if self.enableSleepLogging {
            print("🛏️ Sources found: \(samplesBySource.keys.joined(separator: ", "))")
        }

        guard let preferredSource = SleepDataProcessor.selectPreferredSource(from: Array(samplesBySource.keys)) else {
            return nil
        }

        if self.enableSleepLogging {
            print("🛏️ Using preferred source: \(preferredSource)")
        }

        let sourceSamples = samplesBySource[preferredSource] ?? samples

        if self.enableSleepLogging {
            print("🛏️ Processing \(sourceSamples.count) samples from preferred source")
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
