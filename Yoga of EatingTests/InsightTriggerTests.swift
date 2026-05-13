import XCTest
@testable import Yoga_of_Eating

/// Tests for insight generation trigger wiring in MainViewModel.
/// Phase 4: insightLifecycleService replaces insightService.
@MainActor
final class InsightTriggerTests: XCTestCase {
    var sut: MainViewModel!
    var mockHistorical: MockHistoricalDataService!
    var mockPersistence: MockPersistenceService!
    var mockLogic: MockMealLogicService!
    var mockLifecycle: MockInsightLifecycleService!

    override func setUp() {
        super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        self.mockPersistence = MockPersistenceService()
        self.mockLogic = MockMealLogicService()
        self.mockLifecycle = MockInsightLifecycleService()
        self.sut = MainViewModel(
            logicService: self.mockLogic,
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            insightLifecycleService: self.mockLifecycle,
            skipDataLoading: true
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockHistorical = nil
        self.mockPersistence = nil
        self.mockLogic = nil
        self.mockLifecycle = nil
        super.tearDown()
    }

    // MARK: - Dependency injection

    func test_mainViewModel_hasInsightLifecycleService() {
        XCTAssertNotNil(self.sut.insightLifecycleService)
    }

    func test_mainViewModel_defaultsToRealInsightLifecycleService() {
        let viewModel = MainViewModel(
            logicService: self.mockLogic,
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            skipDataLoading: true
        )
        XCTAssertNotNil(viewModel.insightLifecycleService)
    }

    // MARK: - Trigger after sleep

    func test_saveSleepQuality_triggersInsightGeneration() async {
        self.setupHistoricalDataForInsight()
        self.mockLifecycle.stubbedResult = self.makeInsight()

        self.sut.saveSleepQuality(.good)
        try? await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertTrue(self.mockLifecycle.generateBriefingCalled)
    }

    func test_saveSleepQuality_assignsGeneratedInsight_toCurrentInsight() async {
        self.setupHistoricalDataForInsight()
        let expected = self.makeInsight(headline: "Test headline", dominant: "Test insight text")
        self.mockLifecycle.stubbedResult = expected

        self.sut.saveSleepQuality(.good)
        try? await Task.sleep(nanoseconds: 10_000_000)
        if let task = self.sut.insightTask { await task.value }

        XCTAssertNotNil(self.sut.currentInsight)
        XCTAssertEqual(self.sut.currentInsight?.dominantInsight, "Test insight text")
    }

    func test_currentInsight_makesInsightAvailable() async {
        self.setupHistoricalDataForInsight()
        self.mockLifecycle.stubbedResult = self.makeInsight()

        XCTAssertFalse(self.sut.hasInsightAvailable)

        self.sut.saveSleepQuality(.good)
        try? await Task.sleep(nanoseconds: 10_000_000)
        if let task = self.sut.insightTask { await task.value }

        XCTAssertTrue(self.sut.hasInsightAvailable)
    }

    func test_newInsight_hasUnreadIndicator() async {
        self.setupHistoricalDataForInsight()
        self.mockLifecycle.stubbedResult = self.makeInsight()

        self.sut.saveSleepQuality(.good)
        try? await Task.sleep(nanoseconds: 10_000_000)
        if let task = self.sut.insightTask { await task.value }

        XCTAssertTrue(self.sut.hasUnreadInsight)
    }

    // MARK: - Idempotency

    func test_saveSleepQuality_doesNotRegenerateInsight_ifAlreadyExists() async {
        self.setupHistoricalDataForInsight()
        let existing = self.makeInsight(headline: "Existing")
        self.sut.currentInsight = existing
        self.mockLifecycle.generateBriefingCalled = false

        self.sut.saveSleepQuality(.poor)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(self.mockLifecycle.generateBriefingCalled)
        XCTAssertEqual(self.sut.currentInsight?.headline, "Existing")
    }

    func test_newDay_clearsCurrentInsight() {
        self.sut.currentInsight = self.makeInsight()
        self.sut.resetDay()
        XCTAssertNil(self.sut.currentInsight)
    }

    // MARK: - Smiley long-press

    func test_handleSmileyLongPress_whenInsightAvailable_showsInsightSheet() {
        self.sut.currentInsight = self.makeInsight()
        XCTAssertFalse(self.sut.showInsightSheet)
        self.sut.handleSmileyLongPress()
        XCTAssertTrue(self.sut.showInsightSheet)
    }

    func test_handleSmileyLongPress_whenNoInsight_doesNotShowSheet() {
        self.sut.currentInsight = nil
        self.sut.handleSmileyLongPress()
        XCTAssertFalse(self.sut.showInsightSheet)
    }

    func test_smileyTap_stillCreatesNewMeal() {
        self.sut.currentInsight = self.makeInsight()
        XCTAssertTrue(self.sut.meals.isEmpty)
        self.sut.createNewMeal()
        XCTAssertEqual(self.sut.meals.count, 1)
    }

    // MARK: - Helpers

    private func makeInsight(headline: String = "Test", dominant: String = "Test insight") -> DailyInsight {
        DailyInsight(
            date: Date(),
            headline: headline,
            dimensions: .neutral,
            dominantInsight: dominant,
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

    private func setupHistoricalDataForInsight() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        self.mockHistorical.historicalData.addOrUpdate(snapshot:
            DailySmileySnapshotBuilder().withDate(yesterday)
                .withMeals([MealBuilder().withScore(0.5).build()]).build()
        )
        self.mockHistorical.historicalData.addOrUpdate(snapshot:
            DailySmileySnapshotBuilder().withDate(today)
                .withMeals([MealBuilder().withScore(0.6).build()]).build()
        )
    }
}
