import Foundation
import HealthKit
import OSLog

private let activityLogger = Logger(subsystem: "com.yogaofeating", category: "ActivityData")

// MARK: - ActivityDataProvider conformance

extension HealthKitService: ActivityDataProvider {
    /// Returns total active (exercise) calories for the given calendar day.
    func fetchActiveCaloriesBurned(for date: Date) async -> Double? {
        await self.fetchDailyEnergySum(type: .activeEnergyBurned, for: date)
    }

    /// Returns total basal (resting) calories for the given calendar day.
    func fetchBasalCaloriesBurned(for date: Date) async -> Double? {
        await self.fetchDailyEnergySum(type: .basalEnergyBurned, for: date)
    }

    // MARK: - Private

    /// Sums a quantity type over the calendar day containing `date`.
    private func fetchDailyEnergySum(type identifier: HKQuantityTypeIdentifier, for date: Date) async -> Double? {
        guard let store = self.healthStore,
              let quantityType = HKQuantityType.quantityType(forIdentifier: identifier)
        else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        // TODO: Switch to withCheckedThrowingContinuation so callers can distinguish
        // "permission denied" from "no data" instead of collapsing both to nil.
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error {
                    activityLogger.info("Energy query failed: \(error.localizedDescription, privacy: .public)")
                    continuation.resume(returning: nil)
                    return
                }
                let value = result?.sumQuantity().map { $0.doubleValue(for: .kilocalorie()) }
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}
