import XCTest
@testable import Yoga_of_Eating

@MainActor
final class WeeklySummaryViewModelTests: XCTestCase {
    func test_refreshWeeklyInsight_setsPublishedValue() async {
        let mockHistorical = MockHistoricalDataService()
        let mockInsight = WeeklyInsightMockService()
        mockInsight.mockWeeklyInsight = WeeklyInsight(
            weekStartDate: Date(),
            weekEndDate: Date(),
            summaryText: "Great consistency this week."
        )
        let sut = MainViewModel(
            logicService: MockMealLogicService(),
            persistenceService: MockPersistenceService(),
            historicalService: mockHistorical,
            insightService: mockInsight
        )

        sut.refreshWeeklyInsight()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(sut.currentWeeklyInsight)
        XCTAssertEqual(sut.currentWeeklyInsight?.summaryText, "Great consistency this week.")
        XCTAssertTrue(mockInsight.generateWeeklyInsightCalled)
    }
}

@MainActor
private final class WeeklyInsightMockService: InsightGenerationServiceProtocol {
    var mockWeeklyInsight: WeeklyInsight?
    var generateWeeklyInsightCalled = false

    func gatherDataForInsight() -> [DailySmileySnapshot] { [] }
    func createInsightPrompt(from snapshots: [DailySmileySnapshot]) -> String { "\(snapshots.count)" }
    func saveInsight(_: DailyInsight, for _: Date) {}
    func shouldGenerateInsight(for _: Date) -> Bool { false }
    func generateInsight(for _: Date, healthKitSleepData _: [Date: SleepData]) async throws -> DailyInsight? { nil }
    func generateWeeklyInsight() async -> WeeklyInsight? {
        self.generateWeeklyInsightCalled = true
        return self.mockWeeklyInsight
    }
}
