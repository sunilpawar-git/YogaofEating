import XCTest
@testable import Yoga_of_Eating

/// Integration tests for the Smart Compass feature:
/// smiley long-press routes to BriefingDetailView (with live dimension bars)
/// when a fresh today insight is available; falls back to WellbeingBreakdownSheet otherwise.
@MainActor
final class SmartCompassIntegrationTests: XCTestCase {
    var sut: MainViewModel!
    var mockHistorical: MockHistoricalDataService!
    var mockPersistence: MockPersistenceService!
    var mockLogic: MockMealLogicService!
    var mockLifecycle: MockInsightLifecycleService!
    var mockActivityProvider: MockActivityDataProvider!
    var mockAuth: MockAuthService!

    override func setUp() {
        super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        self.mockPersistence = MockPersistenceService()
        self.mockLogic = MockMealLogicService()
        self.mockLifecycle = MockInsightLifecycleService()
        self.mockActivityProvider = MockActivityDataProvider()
        self.mockAuth = MockAuthService()
        self.mockAuth.currentUser = MockAuthUser(uid: "test_uid")
        self.sut = MainViewModel(
            logicService: self.mockLogic,
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            activityProvider: self.mockActivityProvider,
            insightLifecycleService: self.mockLifecycle,
            authService: self.mockAuth,
            skipDataLoading: true
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockHistorical = nil
        self.mockPersistence = nil
        self.mockLogic = nil
        self.mockLifecycle = nil
        self.mockActivityProvider = nil
        self.mockAuth = nil
        super.tearDown()
    }

    // MARK: - Routing: today with fresh insight

    func test_smileyLongPress_todayInsight_briefingSheetOpens() {
        self.sut.currentInsight = self.makeInsight()
        self.sut.handleSmileyLongPress()
        XCTAssertTrue(self.sut.showBriefingSheet)
        XCTAssertFalse(self.sut.showBreakdownSheet)
    }

    func test_smileyLongPress_todayInsight_breakdownContractIsNonNil() {
        self.sut.currentInsight = self.makeInsight()
        self.sut.meals = [MealBuilder().withScore(0.75).build()]
        XCTAssertNotNil(self.sut.wellbeingBreakdownContract)
    }

    // MARK: - Routing: no insight fallback

    func test_smileyLongPress_noInsight_breakdownFallbackOpens() {
        XCTAssertTrue(self.sut.isViewingToday)
        self.sut.currentInsight = nil
        self.sut.handleSmileyLongPress()
        XCTAssertTrue(self.sut.showBreakdownSheet)
        XCTAssertFalse(self.sut.showBriefingSheet)
    }

    // MARK: - Routing: stale insight

    func test_smileyLongPress_staleInsight_fallbackOpens() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        self.sut.currentInsight = self.makeInsight(date: yesterday)
        self.sut.handleSmileyLongPress()
        XCTAssertTrue(self.sut.showBreakdownSheet)
        XCTAssertFalse(self.sut.showBriefingSheet)
    }

    // MARK: - dimensionBarsSection data integrity

    func test_briefingDetailView_dimensionBars_matchSynthesisValues() {
        // Build a known contract and verify the values match synthesis, not DailyInsight.dimensions
        let contract = WellbeingBreakdownSheetContract(
            dimensions: WellbeingDimensions(
                physicalLoad: 0.85, emotionalTone: 0.5,
                cognitiveClarity: 0.31, behavioralMomentum: 0.1
            ),
            dominantDimension: .physicalLoad,
            causalNarrative: "Test",
            weakDimensions: [.behavioralMomentum],
            mealCount: 2,
            currentMood: .neutral,
            overallScore: 0.44
        )

        let insight = self.makeInsight()
        let view = BriefingDetailView(insight: insight, liveBreakdown: contract)

        // Verify the contract values are passed through correctly
        XCTAssertEqual(view.liveBreakdown?.dimensions.physicalLoad, 0.85)
        XCTAssertEqual(view.liveBreakdown?.dimensions.emotionalTone, 0.5)
        // DailyInsight.dimensions is .neutral (all 0.5) — contract must differ
        XCTAssertNotEqual(insight.dimensions.physicalLoad, 0.85)
    }

    // MARK: - Auto-transition (fallback → briefing when insight generates)

    func test_insightGeneratedWhileFallbackOpen_switchesToBriefing() {
        // Breakdown sheet is showing (fallback state) → insight arrives → must switch
        self.sut.showBreakdownSheet = true
        self.sut.handleInsightGeneratedDuringFallback(self.makeInsight())
        XCTAssertFalse(self.sut.showBreakdownSheet)
        XCTAssertTrue(self.sut.showBriefingSheet)
    }

    func test_insightGeneratedWhileBreakdownNotShown_doesNotOpenBriefing() {
        // No fallback sheet open → insight arriving must NOT auto-open briefing
        self.sut.showBreakdownSheet = false
        self.sut.handleInsightGeneratedDuringFallback(self.makeInsight())
        XCTAssertFalse(self.sut.showBriefingSheet)
    }

    func test_staleInsightGeneratedWhileFallbackOpen_doesNotSwitch() {
        // Yesterday's insight arrives while fallback is open → must NOT transition
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        self.sut.showBreakdownSheet = true
        self.sut.handleInsightGeneratedDuringFallback(self.makeInsight(date: yesterday))
        XCTAssertTrue(self.sut.showBreakdownSheet)
        XCTAssertFalse(self.sut.showBriefingSheet)
    }

    func test_nilInsightWhileFallbackOpen_doesNotSwitch() {
        self.sut.showBreakdownSheet = true
        self.sut.handleInsightGeneratedDuringFallback(nil)
        XCTAssertTrue(self.sut.showBreakdownSheet)
        XCTAssertFalse(self.sut.showBriefingSheet)
    }

    // MARK: - Title format

    func test_briefingDetailView_title_usesInsightDate() {
        let monday = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let title = BriefingDetailView.insightsTitle(for: monday)
        XCTAssertEqual(title, "Monday Insights")
    }

    // MARK: - Helpers

    private func makeInsight(date: Date = Date()) -> DailyInsight {
        DailyInsight(
            date: date,
            headline: "Test headline",
            dimensions: .neutral,
            dominantInsight: "Test insight",
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
}
