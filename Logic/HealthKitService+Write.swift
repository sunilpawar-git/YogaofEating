import Foundation
import HealthKit

/// Abstraction for HealthKit write operations, enabling testability.
protocol HKHealthStoreWritable: Sendable {
    func save(_ object: HKObject) async throws
}

extension HKHealthStore: HKHealthStoreWritable {}

extension HealthKitService {
    /// Logs a mindful session to HealthKit.
    /// Only writes to the device-local HealthKit store — never to Firebase
    /// or any external service.
    func logMindfulSession(start: Date, end: Date) async throws {
        guard let store = writeStore else {
            throw HealthKitError.notAvailable
        }

        guard let mindfulType = HKCategoryType.categoryType(
            forIdentifier: .mindfulSession
        ) else {
            throw HealthKitError.notAvailable
        }

        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: end
        )

        try await store.save(sample)
    }
}
