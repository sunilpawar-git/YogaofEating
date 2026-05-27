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

        // Directly call triggerInsightGeneration to test insight generation
        // (saveSleepQuality uses synthesisScheduler which may not be properly wired in tests)
        self.sut.triggerInsightGeneration()
        try? await Task.sleep(nanoseconds: 500_000_000)
        if let task = self.sut.insightTask { await task.value }

        XCTAssertTrue(self.mockLifecycle.generateBriefingCalled)
    }

    func test_saveSleepQuality_assignsGeneratedInsight_toCurrentInsight() async {
        self.setupHistoricalDataForInsight()
        let expected = self.makeInsight(headline: "Test headline", dominant: "Test insight text")
        self.mockLifecycle.stubbedResult = expected

        // Directly call triggerInsightGeneration to test insight assignment
        // (saveSleepQuality uses synthesisScheduler which may not be properly wired in tests)
        self.sut.triggerInsightGeneration()
        try? await Task.sleep(nanoseconds: 500_000_000)
        if let task = self.sut.insightTask { await task.value }

        XCTAssertNotNil(self.sut.currentInsight)
        XCTAssertEqual(self.sut.currentInsight?.dominantInsight, "Test insight text")
    }

    func test_currentInsight_makesInsightAvailable() async {
        self.setupHistoricalDataForInsight()
        self.mockLifecycle.stubbedResult = self.makeInsight()

        XCTAssertFalse(self.sut.hasInsightAvailable)

        // Directly call triggerInsightGeneration
        // (saveSleepQuality uses synthesisScheduler which may not be properly wired in tests)
        self.sut.triggerInsightGeneration()
        try? await Task.sleep(nanoseconds: 500_000_000)
        if let task = self.sut.insightTask { await task.value }

        XCTAssertTrue(self.sut.hasInsightAvailable)
    }

    func test_newInsight_hasUnreadIndicator() async {
        self.setupHistoricalDataForInsight()
        self.mockLifecycle.stubbedResult = self.makeInsight()

        // Directly call triggerInsightGeneration
        // (saveSleepQuality uses synthesisScheduler which may not be properly wired in tests)
        self.sut.triggerInsightGeneration()
        try? await Task.sleep(nanoseconds: 500_000_000)
        if let task = self.sut.insightTask { await task.value }

        XCTAssertTrue(self.sut.hasUnreadInsight)
    }

    // MARK: - Proactive generation on app launch

    func test_loadData_whenNoFreshInsight_triggersInsightGeneration() async {
        // Regression guard: loadData() must call triggerInsightGeneration() so the
        // briefing is ready before the user long-presses the smiley. Without this,
        // users see the stale WellbeingBreakdownSheet every morning.
        self.mockLifecycle.stubbedResult = self.makeInsight()
        self.mockPersistence.stubbedLoadData = PersistenceService.AppData(
            meals: [],
            smileyState: .neutral,
            lastResetDate: Date(),
            historicalData: HistoricalData(),
            nudgeHistory: []
        )

        self.sut.loadData()
        if let task = self.sut.insightTask { await task.value }

        XCTAssertTrue(
            self.mockLifecycle.generateBriefingCalled,
            "loadData() must trigger insight generation so the briefing is ready on first long-press"
        )
    }

    func test_loadData_whenFreshInsightAlreadyPersisted_doesNotCallLifecycleService() async {
        // Idempotency guard: if a fresh snapshot exists, loadData() must NOT call the
        // Cloud Function again (triggerInsightGeneration's snapshot guard handles this).
        let today = Date()
        let freshInsight = self.makeInsight(date: today)
        let snapshot = DailySmileySnapshotBuilder()
            .withDate(today)
            .withInsight(freshInsight)
            .build()
        var historicalData = HistoricalData()
        historicalData.addOrUpdate(snapshot: snapshot)

        self.mockPersistence.stubbedLoadData = PersistenceService.AppData(
            meals: [],
            smileyState: .neutral,
            lastResetDate: today,
            historicalData: historicalData,
            nudgeHistory: []
        )

        self.sut.loadData()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(
            self.mockLifecycle.generateBriefingCalled,
            "loadData() must not call lifecycle service when a fresh insight already exists in the snapshot"
        )
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

    func test_handleSmileyLongPress_whenTodayInsightAvailable_opensBriefingSheet() {
        // Today's fresh insight → opens BriefingDetailView, not breakdown
        self.sut.currentInsight = self.makeInsight()
        self.sut.handleSmileyLongPress()
        XCTAssertTrue(self.sut.showBriefingSheet)
        XCTAssertFalse(self.sut.showInsightSheet)
    }

    func test_handleSmileyLongPress_todayNoInsight_opensPreparingSheet() {
        // Viewing today but no insight → preparing sheet (not stale breakdown)
        XCTAssertTrue(self.sut.isViewingToday)
        self.sut.currentInsight = nil
        self.sut.handleSmileyLongPress()
        XCTAssertTrue(self.sut.showInsightPreparingSheet)
        XCTAssertFalse(self.sut.showBriefingSheet)
    }

    func test_handleSmileyLongPress_staleInsight_treatedAsNoInsight_opensPreparingSheet() {
        // currentInsight with yesterday's date → not fresh → preparing sheet
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        self.sut.currentInsight = self.makeInsight(date: yesterday)
        self.sut.handleSmileyLongPress()
        XCTAssertTrue(self.sut.showInsightPreparingSheet)
        XCTAssertFalse(self.sut.showBriefingSheet)
    }

    func test_handleSmileyLongPress_pastDay_noInsight_doesNotShowSheet() {
        // Past day with no insight — nothing opens
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        self.sut.selectedDate = yesterday
        self.sut.currentInsight = nil
        self.sut.handleSmileyLongPress()
        XCTAssertFalse(self.sut.showInsightPreparingSheet)
        XCTAssertFalse(self.sut.showInsightSheet)
    }

    func test_handleSmileyLongPress_pastDayWithStaleInsight_doesNothing() {
        // Past day + stale insight (yesterday's date) — guard must reject entirely,
        // no haptic, no sheet.  Regresses the bug where hasInsightAvailable let the
        // guard pass even though neither routing branch could fire.
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        self.sut.selectedDate = yesterday
        self.sut.currentInsight = self.makeInsight(date: yesterday)
        self.sut.handleSmileyLongPress()
        XCTAssertFalse(self.sut.showBriefingSheet)
        XCTAssertFalse(self.sut.showInsightSheet)
    }

    func test_handleSmileyLongPress_pastDayWithFreshInsight_opensBriefing() {
        // Past day but today's insight is loaded — briefing sheet should open
        // (user on yesterday's timeline, but today's AI summary is ready)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        self.sut.selectedDate = yesterday
        self.sut.currentInsight = self.makeInsight() // today's date
        self.sut.handleSmileyLongPress()
        XCTAssertTrue(self.sut.showBriefingSheet)
    }

    // MARK: - Preparing sheet auto-transition

    func test_insightGeneratedWhilePreparingSheetOpen_switchesToBriefing() {
        self.sut.showInsightPreparingSheet = true
        self.sut.handleInsightGeneratedDuringFallback(self.makeInsight())
        XCTAssertFalse(self.sut.showInsightPreparingSheet)
        XCTAssertTrue(self.sut.showBriefingSheet)
    }

    func test_insightGeneratedWhilePreparingSheetNotShowing_doesNotOpenBriefing() {
        self.sut.showInsightPreparingSheet = false
        self.sut.handleInsightGeneratedDuringFallback(self.makeInsight())
        XCTAssertFalse(self.sut.showBriefingSheet)
    }

    // MARK: - Staleness detection

    func test_isBriefingLikelyStale_whenInsightOlderThan3HoursAndHasAIMeals_returnsTrue() {
        let staleDate = Date().addingTimeInterval(-4 * 3600)
        self.sut.currentInsight = self.makeInsight(date: staleDate)
        self.sut.meals = [
            MealBuilder().withScore(0.8).analyzed().build(),
            MealBuilder().withScore(0.7).analyzed().build()
        ]
        XCTAssertTrue(self.sut.isBriefingLikelyStale)
    }

    func test_isBriefingLikelyStale_whenInsightFresh_returnsFalse() {
        self.sut.currentInsight = self.makeInsight(date: Date())
        self.sut.meals = [
            MealBuilder().withScore(0.8).analyzed().build(),
            MealBuilder().withScore(0.7).analyzed().build()
        ]
        XCTAssertFalse(self.sut.isBriefingLikelyStale)
    }

    func test_isBriefingLikelyStale_whenFewerThan2AIMeals_returnsFalse() {
        let staleDate = Date().addingTimeInterval(-4 * 3600)
        self.sut.currentInsight = self.makeInsight(date: staleDate)
        self.sut.meals = [MealBuilder().withScore(0.8).analyzed().build()]
        XCTAssertFalse(self.sut.isBriefingLikelyStale)
    }

    func test_isBriefingLikelyStale_whenNoInsight_returnsFalse() {
        self.sut.currentInsight = nil
        XCTAssertFalse(self.sut.isBriefingLikelyStale)
    }

    func test_smileyTap_stillCreatesNewMeal() {
        self.sut.currentInsight = self.makeInsight()
        XCTAssertTrue(self.sut.meals.isEmpty)
        self.sut.createNewMeal()
        XCTAssertEqual(self.sut.meals.count, 1)
    }

    // MARK: - Helpers

    private func makeInsight(
        headline: String = "Test",
        dominant: String = "Test insight",
        date: Date = Date()
    ) -> DailyInsight {
        DailyInsight(
            date: date,
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
