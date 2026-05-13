import XCTest
@testable import Yoga_of_Eating

/// Tests for InsightLifecycleService.generateBriefing and PatternAnalysisEngine.generateCorrelationCards.
@MainActor
final class InsightServiceTests: XCTestCase {
    // MARK: - InsightLifecycleService.generateBriefing (replaces BriefingService)

    func test_insightLifecycleService_generatesLocalBriefing_independently() async {
        let mockHistorical = MockHistoricalDataService()
        let service = InsightLifecycleService(historicalService: mockHistorical, functions: nil)

        let snapshots = [
            Self.makeSnapshot(daysAgo: 1, score: 0.7),
            Self.makeSnapshot(daysAgo: 2, score: 0.6)
        ]
        for snap in snapshots {
            mockHistorical.historicalData.addOrUpdate(snapshot: snap)
        }

        let insight = await service.generateBriefing(for: Date(), healthKitSleepData: [:])

        XCTAssertNotNil(insight, "InsightLifecycleService must generate a local briefing when Firebase unavailable")
    }

    func test_insightLifecycleService_returnsNil_whenInsufficientData() async {
        let mockHistorical = MockHistoricalDataService()
        let service = InsightLifecycleService(historicalService: mockHistorical, functions: nil)

        let insight = await service.generateBriefing(for: Date(), healthKitSleepData: [:])

        XCTAssertNil(insight, "InsightLifecycleService must return nil when fewer than 2 snapshots available")
    }

    // MARK: - PatternAnalysisEngine parity

    func test_patternAnalysisEngine_generateCorrelationCards_producesValidOutput() {
        let snapshots = Self.makeSnapshotsForPatternAnalysis()
        let engine = PatternAnalysisEngine()
        let cards = engine.generateCorrelationCards(from: snapshots)
        for card in cards {
            XCTAssertGreaterThanOrEqual(card.confidence, 0.0)
            XCTAssertLessThanOrEqual(card.confidence, 1.0)
            XCTAssertFalse(card.observation.isEmpty)
        }
    }

    // MARK: - Helpers

    private static func makeSnapshot(daysAgo: Int, score: Double) -> DailySmileySnapshot {
        let meal = MealBuilder().withItems(["salad"]).withScore(score).analyzed().build()
        return DailySmileySnapshotBuilder()
            .daysAgo(daysAgo)
            .withMeals([meal])
            .build()
    }

    private static func makeSnapshotsForPatternAnalysis() -> [DailySmileySnapshot] {
        (1...5).map { daysAgo in Self.makeSnapshot(daysAgo: daysAgo, score: 0.6) }
    }
}
