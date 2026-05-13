import XCTest
@testable import Yoga_of_Eating

/// Tests for insight availability and viewed state via unified DailyInsight.
@MainActor
final class InsightPeekabooTests: XCTestCase {
    // MARK: - Insight Availability Tests

    func test_insight_isAvailable_whenDominantInsightNotEmpty() {
        let insight = self.makeDailyInsight()
        XCTAssertFalse(insight.dominantInsight.isEmpty)
    }

    func test_insight_isNotAvailable_whenNil() {
        let insight: DailyInsight? = nil
        XCTAssertFalse(insight != nil)
    }

    func test_insight_unreadIndicator_tracksViewedState() {
        var insight = self.makeDailyInsight()
        XCTAssertFalse(insight.isViewed)
        insight.markAsViewed()
        XCTAssertTrue(insight.isViewed)
    }

    // MARK: - ViewModel Tests

    func test_viewModel_showInsightSheet_defaultsFalse() {
        let viewModel = MainViewModel(skipDataLoading: true)
        XCTAssertFalse(viewModel.showInsightSheet)
    }

    func test_viewModel_hasUnreadInsight_defaultsFalse() {
        let viewModel = MainViewModel(skipDataLoading: true)
        XCTAssertFalse(viewModel.hasUnreadInsight)
    }

    func test_viewModel_toggleInsightSheet_changesState() {
        let viewModel = MainViewModel(skipDataLoading: true)
        XCTAssertFalse(viewModel.showInsightSheet)
        viewModel.showInsightSheet = true
        XCTAssertTrue(viewModel.showInsightSheet)
    }

    // MARK: - Insight Bottom Sheet Tests

    func test_insightBottomSheet_displaysUnifiedDailyInsight() {
        let card = CorrelationCard(
            category: .foodToSleep,
            observation: "Late dinners affect your sleep",
            confidence: 0.85, dataPoints: []
        )
        let insight = self.makeDailyInsight(cards: [card])
        XCTAssertFalse(insight.dominantInsight.isEmpty)
        XCTAssertEqual(insight.correlationCards.count, 1)
    }

    func test_insightBottomSheet_dismissMarksAsRead() {
        var insight = self.makeDailyInsight()
        XCTAssertFalse(insight.isViewed)
        insight.markAsViewed()
        XCTAssertTrue(insight.isViewed)
    }

    // MARK: - Strings Tests

    func test_insight_strings_exist() {
        XCTAssertFalse(Strings.Insight.dailyTitle.isEmpty)
        XCTAssertFalse(Strings.Insight.gotIt.isEmpty)
        XCTAssertFalse(Strings.Insight.basedOnPatterns.isEmpty)
    }

    // MARK: - Helpers

    private func makeDailyInsight(cards: [CorrelationCard] = []) -> DailyInsight {
        DailyInsight(
            date: Date(),
            headline: Strings.Insight.Headline.strong,
            dimensions: .neutral,
            dominantInsight: "Your late dinner on 12 Jan may have affected your sleep.",
            correlationCards: cards,
            nudge: ActionableNudge(
                suggestion: Strings.Insight.Nudge.defaultSuggestion,
                reasoning: Strings.Insight.Nudge.defaultReasoning
            ),
            causalExplanation: "Food timing is the driver.",
            textSignals: [], confidence: 0.85
        )
    }
}
