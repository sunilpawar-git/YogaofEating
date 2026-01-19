import Foundation
import HealthKit

/// Service to handle HealthKit interactions for reading body metrics.
class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore: HKHealthStore?

    private init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        } else {
            self.healthStore = nil
        }
    }

    /// Requests authorization to read body metrics from HealthKit.
    func requestAuthorization() async throws -> Bool {
        guard let healthStore else {
            throw NSError(
                domain: "HealthKitService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]
            )
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        // Note: Sleep score is typically derived from sleep analysis data
        // We calculate it in fetchSleepData() based on duration and efficiency

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        return true
    }

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
    /// Returns sleep duration, time in bed, and sleep stages.
    /// - Parameter date: The date to fetch sleep data for (defaults to today)
    /// - Returns: Sleep data including duration, time in bed, and quality score if available
    func fetchSleepData(for date: Date = Date()) async throws -> SleepData? {
        guard let healthStore else { return nil }
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Look back 24 hours to capture last night's sleep
        let startDate = calendar.date(byAdding: .day, value: -1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                // Process sleep samples
                var totalSleepDuration: TimeInterval = 0
                var timeInBed: TimeInterval = 0
                var sleepStart: Date?
                var sleepEnd: Date?

                for sample in samples {
                    let value = sample.value
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)

                    // Track time in bed (all sleep categories)
                    let isInBed = value == HKCategoryValueSleepAnalysis.inBed.rawValue
                    let isAsleep: Bool
                    let isAwake = value == HKCategoryValueSleepAnalysis.awake.rawValue

                    if #available(iOS 16.0, *) {
                        isAsleep = value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                            value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                            value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                            value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    } else {
                        isAsleep = value == HKCategoryValueSleepAnalysis.asleep.rawValue
                    }

                    if isInBed || isAsleep || isAwake {
                        if sleepStart == nil {
                            sleepStart = sample.startDate
                        }
                        sleepEnd = sample.endDate
                        timeInBed += duration
                    }

                    // Track actual sleep (only asleep category)
                    if isAsleep {
                        totalSleepDuration += duration
                    }
                }

                // Calculate sleep score based on duration and efficiency
                let sleepScore = self.calculateSleepScore(
                    sleepDuration: totalSleepDuration,
                    timeInBed: timeInBed,
                    sleepStart: sleepStart,
                    sleepEnd: sleepEnd
                )

                let sleepData = SleepData(
                    sleepDuration: totalSleepDuration,
                    timeInBed: timeInBed,
                    sleepStart: sleepStart,
                    sleepEnd: sleepEnd,
                    sleepScore: sleepScore
                )

                continuation.resume(returning: sleepData)
            }
            healthStore.execute(query)
        }
    }

    /// Calculates a sleep score (0-100) based on sleep duration and efficiency.
    /// Maps to our SleepQuality enum: 80+ = great, 60-79 = good, 40-59 = poor, <40 = terrible
    private func calculateSleepScore(
        sleepDuration: TimeInterval,
        timeInBed: TimeInterval,
        sleepStart _: Date?,
        sleepEnd _: Date?
    ) -> Double? {
        guard sleepDuration > 0, timeInBed > 0 else { return nil }

        // Sleep efficiency (percentage of time in bed actually sleeping)
        let efficiency = (sleepDuration / timeInBed) * 100.0

        // Ideal sleep duration: 7-9 hours
        let hoursSlept = sleepDuration / 3600.0
        let durationScore = if hoursSlept >= 7, hoursSlept <= 9 {
            100.0
        } else if hoursSlept >= 6, hoursSlept < 7 {
            80.0
        } else if hoursSlept > 9, hoursSlept <= 10 {
            85.0
        } else if hoursSlept >= 5, hoursSlept < 6 {
            60.0
        } else if hoursSlept > 10 {
            70.0
        } else {
            40.0
        }

        // Combine duration score (60%) and efficiency (40%)
        let finalScore = (durationScore * 0.6) + (efficiency * 0.4)
        return min(100.0, max(0.0, finalScore))
    }
}

// MARK: - Sleep Data Model

/// Represents sleep data fetched from HealthKit
struct SleepData {
    /// Total time spent sleeping (in seconds)
    let sleepDuration: TimeInterval

    /// Total time in bed (in seconds)
    let timeInBed: TimeInterval

    /// When sleep started
    let sleepStart: Date?

    /// When sleep ended
    let sleepEnd: Date?

    /// Calculated sleep score (0-100)
    let sleepScore: Double?

    /// Maps sleep score to SleepQuality enum
    var sleepQuality: SleepQuality? {
        guard let score = sleepScore else { return nil }

        if score >= 80 {
            return .great
        } else if score >= 60 {
            return .good
        } else if score >= 40 {
            return .poor
        } else {
            return .terrible
        }
    }

    /// Sleep efficiency percentage (0-100)
    var efficiency: Double {
        guard self.timeInBed > 0 else { return 0 }
        return (self.sleepDuration / self.timeInBed) * 100.0
    }

    /// Formatted sleep duration (e.g., "7h 30m")
    var formattedDuration: String {
        let hours = Int(sleepDuration / 3600)
        let minutes = Int((sleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}
