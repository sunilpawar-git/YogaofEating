import XCTest
@testable import Yoga_of_Eating

@MainActor
final class BriefingRemediationTests: XCTestCase {
    // MARK: - Helpers

    private func makeBriefing(isViewed: Bool = false) -> DailyBriefing {
        DailyBriefing(
            date: Date(),
            generatedAt: Date(),
            headline: "Test briefing headline",
            correlationCards: [
                CorrelationCard(
                    category: .foodToSleep,
                    observation: "Test observation",
                    confidence: 0.8
                )
            ],
            nudge: ActionableNudge(
                suggestion: "Try a lighter dinner",
                reasoning: "Late heavy meals correlated with poorer sleep"
            ),
            isViewed: isViewed
        )
    }

    private func makeViewModel(
        historicalService: MockHistoricalDataService? = nil,
        insightService: MockInsightGenerationService? = nil
    ) -> (MainViewModel, MockHistoricalDataService, MockInsightGenerationService) {
        let mockHistorical = historicalService ?? MockHistoricalDataService()
        let mockInsight = insightService ?? MockInsightGenerationService(historicalService: mockHistorical)
        let vm = MainViewModel(
            logicService: MockMealLogicService(),
            persistenceService: MockPersistenceService(),
            historicalService: mockHistorical,
            insightService: mockInsight,
            skipDataLoading: true
        )
        return (vm, mockHistorical, mockInsight)
    }

    // MARK: - A1: Struct mutation — markBriefingViewed

    func test_markBriefingViewed_setsIsViewedTrue() {
        let (vm, _, _) = self.makeViewModel()
        vm.currentBriefing = self.makeBriefing(isViewed: false)

        vm.markBriefingViewed()

        XCTAssertTrue(
            vm.currentBriefing?.isViewed == true,
            "markBriefingViewed must mutate the published currentBriefing, not a temporary copy"
        )
    }

    func test_markBriefingViewed_persistsViaHistoricalService() {
        let (vm, mockHistorical, _) = self.makeViewModel()
        vm.currentBriefing = self.makeBriefing(isViewed: false)

        vm.markBriefingViewed()

        XCTAssertTrue(
            mockHistorical.updateInsightCalled,
            "markBriefingViewed must persist the updated briefing via historicalService.updateInsight"
        )
    }

    // MARK: - A1: Struct mutation — dismissInsight

    func test_dismissInsight_setsIsViewedTrue() {
        let (vm, _, _) = self.makeViewModel()
        vm.currentInsight = LegacyDailyInsight(
            date: Date(),
            insightText: "Test insight",
            insightType: .encouragement,
            confidence: 0.8,
            references: []
        )

        vm.dismissInsight()

        XCTAssertTrue(
            vm.currentInsight?.isViewed == true,
            "dismissInsight must mutate the published currentInsight, not a temporary copy"
        )
    }

    // MARK: - A2: Cold-start hydration

    func test_loadData_hydratesBriefingFromSnapshot() {
        let mockHistorical = MockHistoricalDataService()
        let briefing = self.makeBriefing()
        let snapshot = DailySmileySnapshotBuilder().withInsight(DailyInsight(briefing: briefing)).build()
        mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)

        let (vm, _, _) = self.makeViewModel(historicalService: mockHistorical)
        vm.loadData()

        XCTAssertNotNil(
            vm.currentBriefing,
            "loadData must hydrate currentBriefing from today's persisted snapshot"
        )
    }

    // MARK: - A2: Duplicate generation guard

    func test_triggerBriefingGeneration_skipsWhenSnapshotAlreadyHasBriefing() {
        let mockHistorical = MockHistoricalDataService()
        let briefing = self.makeBriefing()
        let snapshot = DailySmileySnapshotBuilder().withInsight(DailyInsight(briefing: briefing)).build()
        mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)

        let mockInsight = MockInsightGenerationService(historicalService: mockHistorical)
        let (vm, _, _) = self.makeViewModel(historicalService: mockHistorical, insightService: mockInsight)

        vm.triggerBriefingGeneration()

        XCTAssertFalse(
            mockInsight.generateBriefingCalled,
            "triggerBriefingGeneration must not call generateBriefing when snapshot already has a briefing"
        )
        XCTAssertNotNil(
            vm.currentBriefing,
            "triggerBriefingGeneration must restore persisted briefing to in-memory state"
        )
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

        XCTAssertEqual(result.hour, 7, "Default wake hour should be 7")
        XCTAssertEqual(result.minute, 0, "Default wake minute should be 0")
    }

    // MARK: - A5: Notification identifier stability

    func test_briefingNotificationId_isStable() {
        XCTAssertEqual(
            NotificationTimingABTest.briefingNotificationIdentifier,
            "morning_briefing",
            "Notification identifier must be a stable constant matching the cancel call"
        )
    }

    // MARK: - B3: Variant distribution stability

    func test_assignVariant_distribution_isStable() {
        let iterations = 1000
        var counts: [NotificationTimingVariant: Int] = [
            .fixed_730am: 0,
            .adaptive_wakeTime: 0,
            .smartDelay_2min: 0
        ]

        for i in 0..<iterations {
            let userId = "stability-test-\(i)-\(UUID().uuidString)"
            NotificationTimingABTest.resetVariantForUser(userId)
            let variant = NotificationTimingABTest.getCurrentVariant(for: userId)
            counts[variant, default: 0] += 1
            NotificationTimingABTest.resetVariantForUser(userId)
        }

        let tolerance = 0.08
        let fixedRatio = Double(counts[.fixed_730am]!) / Double(iterations)
        let adaptiveRatio = Double(counts[.adaptive_wakeTime]!) / Double(iterations)
        let smartRatio = Double(counts[.smartDelay_2min]!) / Double(iterations)

        XCTAssertTrue(
            abs(fixedRatio - 0.50) < tolerance,
            "fixed_730am expected ~50%, got \(fixedRatio * 100)%"
        )
        XCTAssertTrue(
            abs(adaptiveRatio - 0.25) < tolerance,
            "adaptive_wakeTime expected ~25%, got \(adaptiveRatio * 100)%"
        )
        XCTAssertTrue(
            abs(smartRatio - 0.25) < tolerance,
            "smartDelay_2min expected ~25%, got \(smartRatio * 100)%"
        )
    }
}
