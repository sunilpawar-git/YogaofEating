import HealthKit
import XCTest
@testable import Yoga_of_Eating

final class HealthKitWriteTests: XCTestCase {
    // MARK: - Mock

    final class MockHealthStoreWriter: HKHealthStoreWritable {
        var savedObjects: [HKObject] = []
        var shouldThrow = false

        func save(_ object: HKObject) async throws {
            if self.shouldThrow {
                throw NSError(
                    domain: "HKTest", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Mock error"]
                )
            }
            self.savedObjects.append(object)
        }
    }

    // MARK: - logMindfulSession

    func testLogMindfulSessionSavesCorrectSample() async throws {
        let mockStore = MockHealthStoreWriter()
        let service = HealthKitService(writeStore: mockStore)

        let start = Date()
        let end = start.addingTimeInterval(300)
        try await service.logMindfulSession(start: start, end: end)

        XCTAssertEqual(mockStore.savedObjects.count, 1)

        let sample = mockStore.savedObjects[0] as? HKCategorySample
        XCTAssertNotNil(sample)

        let expectedType = HKCategoryType.categoryType(
            forIdentifier: .mindfulSession
        )
        XCTAssertEqual(sample?.categoryType, expectedType)
        XCTAssertEqual(
            sample?.value,
            HKCategoryValue.notApplicable.rawValue
        )
        XCTAssertEqual(sample?.startDate, start)
        XCTAssertEqual(sample?.endDate, end)
    }

    func testLogMindfulSessionPropagatesError() async {
        let mockStore = MockHealthStoreWriter()
        mockStore.shouldThrow = true
        let service = HealthKitService(writeStore: mockStore)

        let start = Date()
        let end = start.addingTimeInterval(300)

        do {
            try await service.logMindfulSession(start: start, end: end)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(mockStore.savedObjects.count, 0)
        }
    }

    func testLogMindfulSessionDurationMatchesStorageKeyConstant() async throws {
        let mockStore = MockHealthStoreWriter()
        let service = HealthKitService(writeStore: mockStore)

        let end = Date()
        let start = end.addingTimeInterval(
            -StorageKeys.mindfulSessionDuration
        )
        try await service.logMindfulSession(start: start, end: end)

        let sample = mockStore.savedObjects[0] as? HKCategorySample
        let duration = sample?.endDate.timeIntervalSince(
            sample!.startDate
        ) ?? 0
        XCTAssertEqual(
            duration, StorageKeys.mindfulSessionDuration,
            accuracy: 0.001
        )
    }

    // MARK: - Toggle gate

    func testMindfulWriteEnabledDefaultsToFalse() {
        UserDefaults.standard.removeObject(
            forKey: StorageKeys.healthKitMindfulWriteEnabled
        )

        let enabled = UserDefaults.standard.bool(
            forKey: StorageKeys.healthKitMindfulWriteEnabled
        )
        XCTAssertFalse(enabled)
    }

    // MARK: - Integration: completeEveningReview

    @MainActor
    func testCompleteEveningReviewDoesNotCrashWhenMindfulDisabled() {
        UserDefaults.standard.set(
            false,
            forKey: StorageKeys.healthKitMindfulWriteEnabled
        )

        let viewModel = MainViewModel(
            logicService: MockMealLogicService(),
            persistenceService: MockPersistenceService(),
            historicalService: MockHistoricalDataService()
        )

        viewModel.completeEveningReview(
            updatedMorningEntries: [],
            eveningEntries: []
        )

        UserDefaults.standard.removeObject(
            forKey: StorageKeys.healthKitMindfulWriteEnabled
        )
    }

    @MainActor
    func testCompleteEveningReviewDoesNotCrashWhenMindfulEnabled() {
        UserDefaults.standard.set(
            true,
            forKey: StorageKeys.healthKitMindfulWriteEnabled
        )

        let viewModel = MainViewModel(
            logicService: MockMealLogicService(),
            persistenceService: MockPersistenceService(),
            historicalService: MockHistoricalDataService()
        )

        viewModel.completeEveningReview(
            updatedMorningEntries: [],
            eveningEntries: []
        )

        UserDefaults.standard.removeObject(
            forKey: StorageKeys.healthKitMindfulWriteEnabled
        )
    }
}
