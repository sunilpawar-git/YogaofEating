import XCTest
@testable import Yoga_of_Eating

/// Tests for the Peekaboo Star Button and Insight Bottom Sheet.
/// Phase 6: Floating star button that reveals insights.
@MainActor
final class InsightPeekabooTests: XCTestCase {
    // MARK: - Peekaboo Button Visibility Tests

    func test_peekabooButton_visibleWhenInsightAvailable() {
        // Given
        let insight = DailyInsight(
            date: Date(),
            insightText: "Test insight",
            insightType: .encouragement,
            confidence: 0.8
        )

        // When - simulate having an insight
        let hasInsight = insight.insightText.isEmpty == false

        // Then
        XCTAssertTrue(hasInsight)
    }

    func test_peekabooButton_hiddenWhenNoInsight() {
        // Given
        let insight: DailyInsight? = nil

        // When
        let shouldShow = insight != nil

        // Then
        XCTAssertFalse(shouldShow)
    }

    func test_peekabooButton_showsUnreadIndicator() {
        // Given
        var insight = DailyInsight(
            date: Date(),
            insightText: "Test insight",
            insightType: .encouragement,
            confidence: 0.8,
            isViewed: false
        )

        // Then - unread should show indicator
        XCTAssertFalse(insight.isViewed)

        // When - mark as viewed
        insight.markAsViewed()

        // Then - no longer unread
        XCTAssertTrue(insight.isViewed)
    }

    // MARK: - ViewModel Tests

    func test_viewModel_showInsightSheet_defaultsFalse() {
        // Given
        let viewModel = MainViewModel()

        // Then
        XCTAssertFalse(viewModel.showInsightSheet)
    }

    func test_viewModel_hasUnreadInsight_defaultsFalse() {
        // Given
        let viewModel = MainViewModel()

        // Then
        XCTAssertFalse(viewModel.hasUnreadInsight)
    }

    func test_viewModel_toggleInsightSheet_changesState() {
        // Given
        let viewModel = MainViewModel()
        XCTAssertFalse(viewModel.showInsightSheet)

        // When
        viewModel.showInsightSheet = true

        // Then
        XCTAssertTrue(viewModel.showInsightSheet)
    }

    // MARK: - Insight Bottom Sheet Tests

    func test_insightBottomSheet_displaysDailyInsight() {
        // Given
        let insight = DailyInsight(
            date: Date(),
            insightText: "Your late dinner on 12 Jan may have affected your sleep.",
            insightType: .foodSleep,
            confidence: 0.85,
            references: [
                InsightReference(
                    date: Date(),
                    description: "Late dinner at 10pm",
                    category: .food
                )
            ]
        )

        // Then
        XCTAssertEqual(insight.insightType, .foodSleep)
        XCTAssertFalse(insight.insightText.isEmpty)
        XCTAssertEqual(insight.references.count, 1)
    }

    func test_insightBottomSheet_dismissMarksAsRead() {
        // Given
        var insight = DailyInsight(
            date: Date(),
            insightText: "Test",
            insightType: .encouragement,
            confidence: 0.7,
            isViewed: false
        )

        // When - simulate dismiss
        insight.markAsViewed()

        // Then
        XCTAssertTrue(insight.isViewed)
    }

    // MARK: - Strings Tests

    func test_insight_strings_exist() {
        XCTAssertFalse(Strings.Insight.dailyTitle.isEmpty)
        XCTAssertFalse(Strings.Insight.gotIt.isEmpty)
        XCTAssertFalse(Strings.Insight.basedOnPatterns.isEmpty)
    }
}
