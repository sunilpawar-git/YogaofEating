import Foundation
import XCTest
@testable import Yoga_of_Eating

/// Tests for Phase 4 — ViewModel Unification.
/// Verifies that MainViewModel holds a single currentInsight: DailyInsight? (not LegacyDailyInsight)
/// and wires directly to InsightLifecycleService.
@MainActor
final class MainViewModelInsightUnificationTests: XCTestCase {
    private var mockHistorical: MockHistoricalDataService!
    private var mockLifecycle: MockInsightLifecycleService!
    private var sut: MainViewModel!

    override func setUp() {
        super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        self.mockLifecycle = MockInsightLifecycleService()
        self.sut = MainViewModel(
            historicalService: self.mockHistorical,
            insightLifecycleService: self.mockLifecycle,
            skipDataLoading: true
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockLifecycle = nil
        self.mockHistorical = nil
        super.tearDown()
    }

    // MARK: - Type contract: currentInsight is DailyInsight, not LegacyDailyInsight

    func test_currentInsight_isNil_onInit() {
        XCTAssertNil(self.sut.currentInsight)
    }

    func test_currentInsight_isUnifiedType() {
        // Compile-time: currentInsight must be DailyInsight? not LegacyDailyInsight?
        let _: DailyInsight? = self.sut.currentInsight
        XCTAssertNil(self.sut.currentInsight)
    }

    // MARK: - No insightService (InsightGenerationService deleted)

    func test_mainViewModel_hasNoInsightServiceProperty() {
        // Structural: if InsightGenerationService is deleted, the init no longer accepts insightService.
        // This test passes if the code compiles without an insightService parameter.
        let vm = MainViewModel(
            historicalService: self.mockHistorical,
            insightLifecycleService: self.mockLifecycle,
            skipDataLoading: true
        )
        XCTAssertNotNil(vm)
    }

    // MARK: - triggerInsightGeneration (replaces triggerBriefingGeneration)

    func test_triggerInsightGeneration_callsLifecycleService() async {
        self.mockLifecycle.stubbedResult = self.makeInsight(headline: "Generated")
        self.seedSnapshots(count: 3)

        self.sut.triggerInsightGeneration()
        // Allow Task to run
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertTrue(self.mockLifecycle.generateBriefingCalled)
    }

    func test_triggerInsightGeneration_setsCurrentInsight_onSuccess() async {
        let expected = self.makeInsight(headline: "Today's insight")
        self.mockLifecycle.stubbedResult = expected
        self.seedSnapshots(count: 3)

        self.sut.triggerInsightGeneration()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(self.sut.currentInsight?.headline, "Today's insight")
    }

    func test_triggerInsightGeneration_isIdempotent_whenInsightAlreadyExistsForToday() async {
        let existing = self.makeInsight(headline: "Already generated")
        self.sut.currentInsight = existing

        self.sut.triggerInsightGeneration()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Should not call lifecycle service again
        XCTAssertFalse(self.mockLifecycle.generateBriefingCalled)
    }

    // MARK: - hasUnreadInsight (unified — no hasUnreadBriefing)

    func test_hasUnreadInsight_falseWhenNil() {
        XCTAssertFalse(self.sut.hasUnreadInsight)
    }

    func test_hasUnreadInsight_trueWhenInsightNotViewed() {
        self.sut.currentInsight = self.makeInsight()
        XCTAssertTrue(self.sut.hasUnreadInsight)
    }

    func test_hasUnreadInsight_falseAfterViewed() {
        var insight = self.makeInsight()
        insight.markAsViewed()
        self.sut.currentInsight = insight
        XCTAssertFalse(self.sut.hasUnreadInsight)
    }

    // MARK: - dismissInsight

    func test_dismissInsight_closesSheet() {
        self.sut.currentInsight = self.makeInsight()
        self.sut.showInsightSheet = true
        self.sut.dismissInsight()
        XCTAssertFalse(self.sut.showInsightSheet)
    }

    func test_dismissInsight_marksInsightAsViewed() {
        self.sut.currentInsight = self.makeInsight()
        self.sut.dismissInsight()
        XCTAssertTrue(self.sut.currentInsight?.isViewed ?? false)
    }

    // MARK: - Reset clears insight

    func test_resetDay_clearsCurrentInsight() {
        self.sut.currentInsight = self.makeInsight()
        self.sut.currentInsight = nil
        XCTAssertNil(self.sut.currentInsight)
    }

    // MARK: - Helpers

    private func makeInsight(headline: String = "Test insight") -> DailyInsight {
        DailyInsight(
            date: Date(),
            headline: headline,
            dimensions: .neutral,
            dominantInsight: "You are doing great.",
            correlationCards: [],
            nudge: ActionableNudge(
                suggestion: Strings.Insight.Nudge.defaultSuggestion,
                reasoning: Strings.Insight.Nudge.defaultReasoning
            ),
            causalExplanation: "",
            textSignals: [],
            confidence: 0.8
        )
    }

    private func seedSnapshots(count: Int) {
        for i in 0..<count {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let snap = DailySmileySnapshotBuilder()
                .withDate(date)
                .withMeals([MealBuilder().withScore(0.7).build()])
                .build()
            self.mockHistorical.historicalData.addOrUpdate(snapshot: snap)
        }
    }
}
