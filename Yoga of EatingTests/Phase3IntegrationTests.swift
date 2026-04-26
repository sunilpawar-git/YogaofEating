import XCTest
@testable import Yoga_of_Eating

@MainActor
final class Phase3IntegrationTests: XCTestCase {
    func test_bis_and_trend_pipeline_producesPoints() {
        let snapshots = (0..<7).map { idx in
            DailySmileySnapshot.create(
                date: Calendar.current.date(byAdding: .day, value: -idx, to: Date()) ?? Date(),
                smileyState: .neutral,
                meals: [Meal(mealType: .lunch, items: ["Meal"], healthScore: 0.7)],
                reflection: DailyReflection(
                    sleepQuality: .good,
                    morningEnergyLevel: 4,
                    dailyIntention: "Steady",
                    focusRating: 2
                ),
                morningMindCheck: [
                    MindCheckEntry(category: .todo, text: "Task", context: .morning, isAccomplished: true)
                ]
            )
        }
        let points = TrendDataService.buildTrendPoints(snapshots: snapshots, days: 7)
        XCTAssertEqual(points.count, 7)
        XCTAssertTrue(points.allSatisfy { $0.bis >= 0 && $0.bis <= 100 })
    }

    func test_archetype_usesTrendSourceSnapshots() {
        let snapshots = (0..<7).map { idx in
            DailySmileySnapshot.create(
                date: Calendar.current.date(byAdding: .day, value: -idx, to: Date()) ?? Date(),
                smileyState: .neutral,
                meals: [Meal(mealType: .dinner, items: ["Meal"], healthScore: 0.6)],
                reflection: DailyReflection(focusRating: 2)
            )
        }
        let archetype = ArchetypeClassifier.classify(snapshots: snapshots)
        XCTAssertNotNil(archetype.rawValue)
    }

    func test_weekly_summary_refresh_sets_state() async {
        let mockInsight = WeeklyInsightMockService()
        mockInsight.mockWeeklyInsight = WeeklyInsight(
            weekStartDate: Date(),
            weekEndDate: Date(),
            summaryText: "Weekly momentum."
        )
        let sut = MainViewModel(
            logicService: MockMealLogicService(),
            persistenceService: MockPersistenceService(),
            historicalService: MockHistoricalDataService(),
            insightService: mockInsight
        )
        sut.refreshWeeklyInsight()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(sut.currentWeeklyInsight?.summaryText, "Weekly momentum.")
    }

    func test_pdf_export_works_with_archetype_and_bis() throws {
        let insight = WeeklyInsight(
            weekStartDate: Date(),
            weekEndDate: Date(),
            summaryText: "Summary",
            wins: ["Win 1"]
        )
        let url = try PDFExportService.exportWeeklySummary(
            insight: insight,
            archetype: .steadyState,
            bisAverage: 82
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func test_premium_gate_flag_default_false() {
        let premium = PremiumManager()
        XCTAssertFalse(premium.isPremium)
    }

    func test_premium_gate_flag_canEnable() {
        let premium = PremiumManager()
        premium.setPremiumForTesting(true)
        XCTAssertTrue(premium.isPremium)
    }
}

@MainActor
private final class WeeklyInsightMockService: InsightGenerationServiceProtocol {
    var mockWeeklyInsight: WeeklyInsight?
    func gatherDataForInsight() -> [DailySmileySnapshot] { [] }
    func createInsightPrompt(from snapshots: [DailySmileySnapshot]) -> String { "\(snapshots.count)" }
    func saveInsight(_: DailyInsight, for _: Date) {}
    func shouldGenerateInsight(for _: Date) -> Bool { false }
    func generateInsight(for _: Date, healthKitSleepData _: [Date: SleepData]) async throws -> DailyInsight? { nil }
    func generateWeeklyInsight() async -> WeeklyInsight? { self.mockWeeklyInsight }
}
