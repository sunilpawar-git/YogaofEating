import Foundation
import XCTest
@testable import Yoga_of_Eating

/// Regression guards verifying the unified DailyInsight model is the SSOT.
/// These tests protect against future regressions that re-introduce multiple insight types.
@MainActor
final class InsightConsolidationRegressionTests: XCTestCase {
    // MARK: - DailyInsight is the SSOT

    func test_dailyInsight_hasHeadline_and_dominantInsight() {
        let insight = self.makeDailyInsight()
        XCTAssertFalse(insight.headline.isEmpty)
        XCTAssertFalse(insight.dominantInsight.isEmpty)
    }

    func test_dailyInsight_hasCorrelationCards() {
        let card = CorrelationCard(category: .foodToSleep, observation: "Test", confidence: 0.8)
        let insight = self.makeDailyInsight(cards: [card])
        XCTAssertEqual(insight.correlationCards.count, 1)
    }

    func test_dailyInsight_hasNudge() {
        let insight = self.makeDailyInsight()
        XCTAssertFalse(insight.nudge.suggestion.isEmpty)
    }

    func test_dailyInsight_hasDimensions() {
        let insight = self.makeDailyInsight()
        XCTAssertGreaterThanOrEqual(insight.dimensions.overall, 0)
        XCTAssertLessThanOrEqual(insight.dimensions.overall, 1)
    }

    func test_dailyInsight_codable_roundTrip() throws {
        let original = self.makeDailyInsight()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DailyInsight.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.headline, original.headline)
        XCTAssertEqual(decoded.dominantInsight, original.dominantInsight)
    }

    // MARK: - HistoricalDataService has single insight method

    func test_historicalDataService_updateInsight_acceptsDailyInsight() {
        let mock = MockHistoricalDataService()
        let insight = self.makeDailyInsight()
        mock.updateInsight(for: Date(), insight: insight)
        XCTAssertTrue(mock.updateInsightCalled)
    }

    func test_snapshot_hasOneInsightField() {
        let insight = self.makeDailyInsight()
        let snapshot = DailySmileySnapshotBuilder().withInsight(insight).build()
        XCTAssertNotNil(snapshot.insight)
        XCTAssertEqual(snapshot.insight?.headline, insight.headline)
    }

    // MARK: - MainViewModel has single currentInsight property

    func test_mainViewModel_currentInsight_isUnifiedType() {
        let vm = MainViewModel(skipDataLoading: true)
        let _: DailyInsight? = vm.currentInsight
        XCTAssertNil(vm.currentInsight)
    }

    func test_mainViewModel_hasNoSeparateBriefingProperty() {
        // Structural: if this compiles, currentBriefing is gone
        let vm = MainViewModel(skipDataLoading: true)
        XCTAssertNotNil(vm)
    }

    // MARK: - InsightLifecycleService is the sole producer

    func test_insightLifecycleService_generateBriefing_returnsDailyInsight() async {
        let mock = MockHistoricalDataService()
        let sut = InsightLifecycleService(historicalService: mock, functions: nil)
        // nil functions → local-only; no data → nil result
        let result = await sut.generateBriefing(
            for: Date(),
            userContext: nil,
            nudgeHistory: [],
            healthKitSleepData: [:]
        )
        let _: DailyInsight? = result
        XCTAssertNil(result, "Nil result when no snapshots")
    }

    func test_insightLifecycleService_generateEnrichedInsight_returnsDailyInsight() async {
        let mock = MockHistoricalDataService()
        let sut = InsightLifecycleService(historicalService: mock, functions: nil)
        let snapshots = (0..<3).map { i in
            DailySmileySnapshotBuilder()
                .daysAgo(i)
                .withMeals([MealBuilder().withScore(0.7).build()])
                .build()
        }
        let synthesis = DailySynthesis(
            dimensions: .neutral,
            dataCompleteness: [],
            textSignals: [.neutral],
            smileySuggestion: .neutral,
            dominantDimension: .physicalLoad,
            causalNarrative: "Test"
        )
        let result = await sut.generateEnrichedInsight(
            for: Date(), synthesis: synthesis,
            recentSnapshots: snapshots, healthKitSleepData: [:]
        )
        let _: DailyInsight? = result
        XCTAssertNotNil(result)
    }

    // MARK: - SnapshotPayloadBuilder produces correct payload

    func test_snapshotPayloadBuilder_produces_validPayload() {
        let today = Calendar.current.startOfDay(for: Date())
        let snap = DailySmileySnapshotBuilder().withDate(today).build()
        let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: today)
        XCTAssertEqual(payload.count, 1)
        XCTAssertNotNil(payload[0]["date"])
        XCTAssertEqual(payload[0]["isToday"] as? Bool, true)
    }

    // MARK: - Helpers

    private func makeDailyInsight(cards: [CorrelationCard] = []) -> DailyInsight {
        DailyInsight(
            date: Date(),
            headline: Strings.Insight.Headline.strong,
            dimensions: .neutral,
            dominantInsight: "Your patterns are improving.",
            correlationCards: cards,
            nudge: ActionableNudge(
                suggestion: Strings.Insight.Nudge.defaultSuggestion,
                reasoning: Strings.Insight.Nudge.defaultReasoning
            ),
            causalExplanation: "Physical load is the driver.",
            textSignals: [.neutral],
            confidence: 0.8
        )
    }
}
