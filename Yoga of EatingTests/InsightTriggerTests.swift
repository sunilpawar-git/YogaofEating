import XCTest
@testable import Yoga_of_Eating

/// Tests for insight generation trigger wiring.
/// Phase 1-4: TDD tests for connecting InsightGenerationService to MainViewModel.
@MainActor
final class InsightTriggerTests: XCTestCase {
    // MARK: - Properties

    var sut: MainViewModel!
    var mockHistorical: MockHistoricalDataService!
    var mockPersistence: MockPersistenceService!
    var mockLogic: MockMealLogicService!
    var mockInsightService: MockInsightGenerationService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        self.mockPersistence = MockPersistenceService()
        self.mockLogic = MockMealLogicService()
        self.mockInsightService = MockInsightGenerationService(historicalService: self.mockHistorical)
        self.sut = MainViewModel(
            logicService: self.mockLogic,
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            insightService: self.mockInsightService
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockHistorical = nil
        self.mockPersistence = nil
        self.mockLogic = nil
        self.mockInsightService = nil
        super.tearDown()
    }

    // MARK: - Phase 1: InsightGenerationService Dependency Injection

    func test_mainViewModel_hasInsightService() {
        // Then: ViewModel should have an insight service
        XCTAssertNotNil(self.sut.insightService)
    }

    func test_mainViewModel_defaultsToRealInsightService() {
        // Given: Create ViewModel without mock
        let viewModel = MainViewModel(
            logicService: self.mockLogic,
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical
        )

        // Then: Should have a real insight service (not nil)
        XCTAssertNotNil(viewModel.insightService)
    }

    // MARK: - Phase 2: Trigger Insight Generation After Sleep Quality Saved

    func test_saveSleepQuality_triggersInsightGeneration() async {
        // Given: Setup historical data so insight can be generated
        self.setupHistoricalDataForInsight()

        // When: Save sleep quality
        self.sut.saveSleepQuality(.good)

        // Wait for async task to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then: Insight generation should be triggered
        XCTAssertTrue(self.mockInsightService.generateInsightCalled)
    }

    func test_saveSleepQuality_doesNotTriggerInsight_whenNoHistoricalData() async {
        // Given: No historical data

        // When: Save sleep quality
        self.sut.saveSleepQuality(.good)

        // Wait for async task
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Insight generation should not be triggered (conditions not met)
        // The service is called but returns nil
        XCTAssertTrue(self.mockInsightService.generateInsightCalled)
        XCTAssertNil(self.sut.currentInsight)
    }

    // MARK: - Phase 3: Assign Generated Insight to currentInsight

    func test_saveSleepQuality_assignsGeneratedInsight_toCurrentInsight() async {
        // Given: Setup data and mock insight
        self.setupHistoricalDataForInsight()
        let expectedInsight = DailyInsight(
            date: Date(),
            insightText: "Test insight text",
            insightType: .foodSleep,
            confidence: 0.8
        )
        self.mockInsightService.mockInsight = expectedInsight

        // When: Save sleep quality
        self.sut.saveSleepQuality(.good)

        // Wait for insight task to complete
        if let insightTask = self.sut.insightTask {
            await insightTask.value
        }

        // Then: currentInsight should be set
        XCTAssertNotNil(self.sut.currentInsight)
        XCTAssertEqual(self.sut.currentInsight?.insightText, "Test insight text")
    }

    func test_currentInsight_makesInsightAvailable() async {
        // Given: Setup data and mock insight
        self.setupHistoricalDataForInsight()
        self.mockInsightService.mockInsight = DailyInsight(
            date: Date(),
            insightText: "Your patterns show...",
            insightType: .encouragement,
            confidence: 0.7
        )

        // Initially no insight should be available
        XCTAssertFalse(self.sut.hasInsightAvailable)

        // When: Save sleep quality to trigger insight
        self.sut.saveSleepQuality(.good)

        // Wait for insight task to complete
        if let insightTask = self.sut.insightTask {
            await insightTask.value
        }

        // Then: Insight should now be available
        XCTAssertTrue(self.sut.hasInsightAvailable)
    }

    func test_newInsight_hasUnreadIndicator() async {
        // Given: Setup data and mock insight (not viewed)
        self.setupHistoricalDataForInsight()
        self.mockInsightService.mockInsight = DailyInsight(
            date: Date(),
            insightText: "New insight",
            insightType: .pattern,
            confidence: 0.75,
            isViewed: false
        )

        // When: Trigger insight generation
        self.sut.saveSleepQuality(.good)

        // Wait for insight task to complete
        if let insightTask = self.sut.insightTask {
            await insightTask.value
        }

        // Then: Should show unread indicator
        XCTAssertTrue(self.sut.hasUnreadInsight)
    }

    // MARK: - Phase 4: Prevent Duplicate Insight Generation

    func test_saveSleepQuality_doesNotRegenerateInsight_ifAlreadyExists() async {
        // Given: Already have an insight
        self.setupHistoricalDataForInsight()
        let existingInsight = DailyInsight(
            date: Date(),
            insightText: "Existing insight",
            insightType: .foodSleep,
            confidence: 0.9
        )
        self.sut.currentInsight = existingInsight
        self.mockInsightService.generateInsightCalled = false

        // When: Save sleep quality again
        self.sut.saveSleepQuality(.poor)

        // Wait for async task
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should NOT regenerate insight (already exists for today)
        XCTAssertFalse(self.mockInsightService.generateInsightCalled)
        XCTAssertEqual(self.sut.currentInsight?.insightText, "Existing insight")
    }

    func test_newDay_clearsCurrentInsight() {
        // Given: Have an insight from previous day
        self.sut.currentInsight = DailyInsight(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            insightText: "Yesterday's insight",
            insightType: .encouragement,
            confidence: 0.7
        )

        // When: Reset day (simulating new day)
        self.sut.resetDay()

        // Then: currentInsight should be cleared
        XCTAssertNil(self.sut.currentInsight)
    }

    // MARK: - Phase 2: Smiley Long-Press Tests

    func test_handleSmileyLongPress_whenInsightAvailable_showsInsightSheet() {
        // Given: Have an insight available
        self.sut.currentInsight = DailyInsight(
            date: Date(),
            insightText: "Test insight",
            insightType: .encouragement,
            confidence: 0.8
        )
        XCTAssertFalse(self.sut.showInsightSheet)

        // When: Long-press on smiley
        self.sut.handleSmileyLongPress()

        // Then: Insight sheet should be shown
        XCTAssertTrue(self.sut.showInsightSheet)
    }

    func test_handleSmileyLongPress_whenNoInsight_doesNotShowSheet() {
        // Given: No insight available
        self.sut.currentInsight = nil
        XCTAssertFalse(self.sut.showInsightSheet)

        // When: Long-press on smiley
        self.sut.handleSmileyLongPress()

        // Then: Insight sheet should NOT be shown
        XCTAssertFalse(self.sut.showInsightSheet)
    }

    func test_smileyTap_stillCreatesNewMeal() {
        // Given: Have an insight available (should not interfere with tap)
        self.sut.currentInsight = DailyInsight(
            date: Date(),
            insightText: "Test insight",
            insightType: .pattern,
            confidence: 0.7
        )
        XCTAssertTrue(self.sut.meals.isEmpty)

        // When: Normal tap (not long-press)
        self.sut.createNewMeal()

        // Then: Meal should be created
        XCTAssertEqual(self.sut.meals.count, 1)
    }

    // MARK: - Helpers

    private func setupHistoricalDataForInsight() {
        let calendar = Calendar.current
        let today = Date()

        // Add yesterday's data
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let yesterdaySnapshot = DailySmileySnapshotBuilder()
            .withDate(yesterday)
            .withMeals([MealBuilder().withMealType(.dinner).withItems(["Pasta"]).withScore(0.5).build()])
            .build()
        self.mockHistorical.historicalData.addOrUpdate(snapshot: yesterdaySnapshot)

        // Add today's snapshot (will be updated with sleep)
        let todaySnapshot = DailySmileySnapshotBuilder()
            .withDate(today)
            .withMeals([MealBuilder().withMealType(.breakfast).withItems(["Toast"]).withScore(0.6).build()])
            .build()
        self.mockHistorical.historicalData.addOrUpdate(snapshot: todaySnapshot)
    }
}

// MARK: - Mock InsightGenerationService

@MainActor
class MockInsightGenerationService: InsightGenerationServiceProtocol {
    private let historicalService: any HistoricalDataServiceProtocol

    var generateInsightCalled = false
    var mockInsight: DailyInsight?
    var generateWeeklyInsightCalled = false
    var mockWeeklyInsight: WeeklyInsight?

    init(historicalService: any HistoricalDataServiceProtocol) {
        self.historicalService = historicalService
    }

    func gatherDataForInsight() -> [DailySmileySnapshot] {
        let calendar = Calendar.current
        var snapshots: [DailySmileySnapshot] = []
        for daysAgo in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            if let snapshot = self.historicalService.getSnapshot(for: date), !snapshot.isEmpty {
                snapshots.append(snapshot)
            }
        }
        return snapshots
    }

    func createInsightPrompt(from snapshots: [DailySmileySnapshot]) -> String {
        "Mock prompt for \(snapshots.count) snapshots"
    }

    func saveInsight(_: DailyInsight, for _: Date) {
        // No-op for mock
    }

    func shouldGenerateInsight(for date: Date) -> Bool {
        guard let snapshot = self.historicalService.getSnapshot(for: date) else {
            return false
        }
        guard let reflection = snapshot.reflection, reflection.sleepQuality != nil else {
            return false
        }
        let data = self.gatherDataForInsight()
        return data.count >= 2
    }

    func generateInsight(for date: Date, healthKitSleepData _: [Date: SleepData] = [:]) async throws -> DailyInsight? {
        self.generateInsightCalled = true
        guard self.shouldGenerateInsight(for: date) else {
            return nil
        }
        return self.mockInsight
    }

    func generateWeeklyInsight() async -> WeeklyInsight? {
        self.generateWeeklyInsightCalled = true
        return self.mockWeeklyInsight
    }

    var generateBriefingCalled = false
    var mockBriefing: DailyBriefing?

    func generateBriefing(for _: Date, healthKitSleepData _: [Date: SleepData]) async -> DailyBriefing? {
        self.generateBriefingCalled = true
        return self.mockBriefing
    }
}
