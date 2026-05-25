import XCTest
@testable import Yoga_of_Eating

@MainActor
final class BriefingRemediationTests: XCTestCase {
    private func makeInsight(headline: String = "Test insight", isViewed: Bool = false) -> DailyInsight {
        DailyInsight(
            date: Date(),
            headline: headline,
            dimensions: .neutral,
            dominantInsight: "Your patterns show improvement.",
            correlationCards: [
                CorrelationCard(category: .foodToSleep, observation: "Test observation", confidence: 0.8)
            ],
            nudge: ActionableNudge(
                suggestion: Strings.Insight.Nudge.defaultSuggestion,
                reasoning: Strings.Insight.Nudge.defaultReasoning
            ),
            causalExplanation: "",
            textSignals: [],
            confidence: 0.8,
            isViewed: isViewed
        )
    }

    private func makeViewModel(
        historicalService: MockHistoricalDataService? = nil,
        lifecycleService: MockInsightLifecycleService? = nil
    ) -> (MainViewModel, MockHistoricalDataService, MockInsightLifecycleService) {
        let mockHistorical = historicalService ?? MockHistoricalDataService()
        let mockLifecycle = lifecycleService ?? MockInsightLifecycleService()
        let authService = MockAuthService()
        authService.currentUser = MockAuthUser(uid: "test_uid")
        let vm = MainViewModel(
            logicService: MockMealLogicService(),
            persistenceService: MockPersistenceService(),
            historicalService: mockHistorical,
            insightLifecycleService: mockLifecycle,
            authService: authService,
            skipDataLoading: true
        )
        return (vm, mockHistorical, mockLifecycle)
    }

    // MARK: - markBriefingViewed → marks unified currentInsight

    func test_markBriefingViewed_setsIsViewedTrue() {
        let (vm, _, _) = self.makeViewModel()
        vm.currentInsight = self.makeInsight(isViewed: false)

        vm.markBriefingViewed()

        XCTAssertTrue(
            vm.currentInsight?.isViewed == true,
            "markBriefingViewed must mutate the published currentInsight"
        )
    }

    func test_markBriefingViewed_persistsViaHistoricalService() {
        let (vm, mockHistorical, _) = self.makeViewModel()
        vm.currentInsight = self.makeInsight(isViewed: false)

        vm.markBriefingViewed()

        XCTAssertTrue(
            mockHistorical.updateInsightCalled,
            "markBriefingViewed must persist via historicalService.updateInsight"
        )
    }

    // MARK: - dismissInsight marks unified insight

    func test_dismissInsight_setsIsViewedTrue() {
        let (vm, _, _) = self.makeViewModel()
        vm.currentInsight = self.makeInsight()

        vm.dismissInsight()

        XCTAssertTrue(
            vm.currentInsight?.isViewed == true,
            "dismissInsight must mutate the published currentInsight"
        )
    }

    // MARK: - Cold-start hydration from persisted snapshot

    func test_loadData_hydratesCurrentInsightFromSnapshot() {
        let mockHistorical = MockHistoricalDataService()
        let today = Calendar.current.startOfDay(for: Date())
        let insight = self.makeInsight()
        mockHistorical.historicalData.addOrUpdate(
            snapshot: DailySmileySnapshotBuilder().withDate(today).withInsight(insight).build()
        )

        let (vm, _, _) = self.makeViewModel(historicalService: mockHistorical)
        vm.loadData()

        XCTAssertNotNil(vm.currentInsight, "loadData must hydrate currentInsight from today's snapshot")
    }

    // MARK: - Duplicate generation guard

    func test_triggerInsightGeneration_skipsWhenInsightAlreadyExistsForToday() {
        let mockHistorical = MockHistoricalDataService()
        let today = Calendar.current.startOfDay(for: Date())
        let insight = self.makeInsight(headline: "Already generated")
        mockHistorical.historicalData.addOrUpdate(
            snapshot: DailySmileySnapshotBuilder().withDate(today).withInsight(insight).build()
        )

        let mockLifecycle = MockInsightLifecycleService()
        let (vm, _, _) = self.makeViewModel(historicalService: mockHistorical, lifecycleService: mockLifecycle)

        vm.triggerInsightGeneration()

        XCTAssertFalse(
            mockLifecycle.generateBriefingCalled,
            "triggerInsightGeneration must not call lifecycle when insight already persisted for today"
        )
        XCTAssertNotNil(vm.currentInsight, "Must restore persisted insight to in-memory state")
    }

    // MARK: - A3: WakeTimePredictor parsing

    func test_predictWakeTime_parsesValidStoredTime() {
        let userId = "test-wake-\(UUID().uuidString)"
        UserDefaults.standard.set("6:30", forKey: "user_wake_time_\(userId)")
        defer { UserDefaults.standard.removeObject(forKey: "user_wake_time_\(userId)") }

        let result = WakeTimePredictor.predictWakeTime(for: userId)

        XCTAssertEqual(result.hour, 6)
        XCTAssertEqual(result.minute, 30)
    }

    func test_predictWakeTime_returnsDefaultForInvalid() {
        let userId = "test-invalid-\(UUID().uuidString)"
        UserDefaults.standard.set("", forKey: "user_wake_time_\(userId)")
        defer { UserDefaults.standard.removeObject(forKey: "user_wake_time_\(userId)") }

        let result = WakeTimePredictor.predictWakeTime(for: userId)

        XCTAssertEqual(result.hour, 7)
        XCTAssertEqual(result.minute, 0)
    }

    // MARK: - A5: Notification identifier stability

    func test_briefingNotificationId_isStable() {
        XCTAssertEqual(
            NotificationTimingABTest.briefingNotificationIdentifier,
            "morning_briefing",
            "The notification identifier must never change — iOS caches it"
        )
    }
}
