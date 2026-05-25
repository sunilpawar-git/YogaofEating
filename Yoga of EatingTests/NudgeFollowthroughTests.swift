import XCTest
@testable import Yoga_of_Eating

@MainActor
final class NudgeFollowthroughTests: XCTestCase {
    // MARK: - Helpers

    private func makeVM(with insight: DailyInsight? = nil) -> MainViewModel {
        let authService = MockAuthService()
        authService.currentUser = MockAuthUser(uid: "test_uid")
        let vm = MainViewModel(
            persistenceService: MockPersistenceService(),
            historicalService: MockHistoricalDataService(),
            authService: authService,
            skipDataLoading: true
        )
        vm.currentInsight = insight
        return vm
    }

    private func makeInsight(suggestion: String = "Try a walk") -> DailyInsight {
        DailyInsight(
            date: Date(),
            headline: "Test Headline",
            dimensions: .neutral,
            dominantInsight: "Test insight",
            correlationCards: [],
            nudge: ActionableNudge(suggestion: suggestion, reasoning: "Because"),
            causalExplanation: "",
            textSignals: [],
            confidence: 0.8
        )
    }

    // MARK: - dismissInsight

    func test_dismissInsight_withValidNudge_appendsToNudgeHistory() {
        let insight = self.makeInsight(suggestion: "Try a morning walk")
        let vm = self.makeVM(with: insight)

        vm.dismissInsight()

        XCTAssertEqual(vm.nudgeHistory.count, 1)
        XCTAssertEqual(vm.nudgeHistory.first?.suggestion, "Try a morning walk")
    }

    func test_dismissInsight_whenHistoryAt14_dropsOldestEntry() {
        let vm = self.makeVM()
        let oldEntry = NudgeHistoryEntry(
            id: UUID(),
            date: Date(timeIntervalSince1970: 0),
            suggestion: "Oldest nudge"
        )
        vm.nudgeHistory = [oldEntry] + (1..<14).map { i in
            NudgeHistoryEntry(
                id: UUID(),
                date: Date(timeIntervalSince1970: Double(i)),
                suggestion: "Nudge \(i)"
            )
        }

        let insight = self.makeInsight(suggestion: "Newest nudge")
        vm.currentInsight = insight
        vm.dismissInsight()

        XCTAssertEqual(vm.nudgeHistory.count, ValidationLimits.nudgeHistoryMaxEntries)
        XCTAssertFalse(vm.nudgeHistory.contains { $0.suggestion == "Oldest nudge" })
        XCTAssertEqual(vm.nudgeHistory.last?.suggestion, "Newest nudge")
    }

    // MARK: - markNudgeFollowedThrough

    func test_markNudgeFollowedThrough_updatesExistingEntry() {
        let vm = self.makeVM()
        let id = UUID()
        let entry = NudgeHistoryEntry(id: id, date: Date(), suggestion: "Try meditation")
        vm.nudgeHistory = [entry]

        vm.markNudgeFollowedThrough(id: id)

        XCTAssertEqual(vm.nudgeHistory.first?.wasFollowedThrough, true)
    }

    // MARK: - Payload builder

    func test_payloadBuilder_includes14NudgeHistoryEntries() {
        let entries = (0..<14).map { i in
            NudgeHistoryEntry(
                id: UUID(),
                date: Date(timeIntervalSince1970: Double(i)),
                suggestion: "Nudge \(i)"
            )
        }
        let payload = SnapshotPayloadBuilder.build(
            from: [],
            userContext: nil,
            nudgeHistory: entries,
            healthKitSleepData: [:],
            relativeTo: Date()
        )
        let history = payload["nudgeHistory"] as? [[String: Any]]
        XCTAssertEqual(history?.count, 14)
    }

    func test_payloadBuilder_withEmptyHistory_omitsNudgeHistoryKey() {
        let payload = SnapshotPayloadBuilder.build(
            from: [],
            userContext: nil,
            nudgeHistory: [],
            healthKitSleepData: [:],
            relativeTo: Date()
        )
        XCTAssertNil(payload["nudgeHistory"])
    }

    // MARK: - Persistence

    func test_dismissInsight_persistsNudgeHistoryToDisk() {
        let mockPersistence = MockPersistenceService()
        let authService = MockAuthService()
        authService.currentUser = MockAuthUser(uid: "test_uid")
        let vm = MainViewModel(
            persistenceService: mockPersistence,
            historicalService: MockHistoricalDataService(),
            authService: authService,
            skipDataLoading: true
        )
        vm.currentInsight = self.makeInsight(suggestion: "Stay hydrated")

        vm.dismissInsight()

        XCTAssertTrue(mockPersistence.saveCalled, "dismissInsight must persist nudge history immediately")
        XCTAssertEqual(mockPersistence.savedData?.nudgeHistory.first?.suggestion, "Stay hydrated")
    }
}
