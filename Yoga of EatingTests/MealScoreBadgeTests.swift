#if canImport(XCTest)
    import SwiftUI
    import XCTest
    @testable import Yoga_of_Eating

    final class MealScoreBadgeTests: XCTestCase {
        // MARK: - shouldDisplay Logic

        func test_shouldDisplay_falseWhenScoreIsZero() {
            let badge = MealScoreBadge(score: 0.0, onTap: {})
            XCTAssertFalse(badge.shouldDisplay, "Badge should be hidden for unanalyzed (0.0) meals")
        }

        func test_shouldDisplay_falseWhenScoreIsNil() {
            let badge = MealScoreBadge(score: nil, onTap: {})
            XCTAssertFalse(badge.shouldDisplay, "Badge should be hidden when score is nil")
        }

        func test_shouldDisplay_trueWhenScoreIsPositive() {
            let badge = MealScoreBadge(score: 0.75, onTap: {})
            XCTAssertTrue(badge.shouldDisplay, "Badge should be visible for AI-analyzed meals with positive score")
        }

        func test_shouldDisplay_trueForLowAIScore() {
            let badge = MealScoreBadge(score: 0.2, onTap: {})
            XCTAssertTrue(badge.shouldDisplay, "Badge should be visible even for low scores (0.2)")
        }

        func test_shouldDisplay_trueForHighAIScore() {
            let badge = MealScoreBadge(score: 0.95, onTap: {})
            XCTAssertTrue(badge.shouldDisplay, "Badge should be visible for excellent scores")
        }

        // MARK: - Formatted Score

        func test_formattedScore_returnsEmptyForZeroScore() {
            let badge = MealScoreBadge(score: 0.0, onTap: {})
            XCTAssertEqual(badge.formattedScore, "")
        }

        func test_formattedScore_returnsEmptyForNil() {
            let badge = MealScoreBadge(score: nil, onTap: {})
            XCTAssertEqual(badge.formattedScore, "")
        }

        func test_formattedScore_75Percent() {
            let badge = MealScoreBadge(score: 0.75, onTap: {})
            XCTAssertEqual(badge.formattedScore, "75%")
        }

        func test_formattedScore_roundsDown() {
            let badge = MealScoreBadge(score: 0.756, onTap: {})
            XCTAssertEqual(badge.formattedScore, "75%", "Should round down (truncate) to integer")
        }

        func test_formattedScore_singleDigit() {
            let badge = MealScoreBadge(score: 0.05, onTap: {})
            XCTAssertEqual(badge.formattedScore, "5%")
        }

        func test_formattedScore_100Percent() {
            let badge = MealScoreBadge(score: 1.0, onTap: {})
            XCTAssertEqual(badge.formattedScore, "100%")
        }

        // MARK: - Color Selection

        func test_badgeColor_exceeds75() {
            let badge = MealScoreBadge(score: 0.8, onTap: {})
            XCTAssertEqual(badge.badgeColor, Color(red: 0.5, green: 0.65, blue: 0.55))
        }

        func test_badgeColor_betweenHealthyAndExcellent() {
            let badge = MealScoreBadge(score: 0.65, onTap: {})
            XCTAssertEqual(badge.badgeColor, Color(red: 0.5, green: 0.6, blue: 0.7))
        }

        func test_badgeColor_moderate() {
            let badge = MealScoreBadge(score: 0.45, onTap: {})
            XCTAssertEqual(badge.badgeColor, Color(red: 0.65, green: 0.6, blue: 0.55))
        }

        func test_badgeColor_low() {
            let badge = MealScoreBadge(score: 0.2, onTap: {})
            XCTAssertEqual(badge.badgeColor, Color(red: 0.55, green: 0.55, blue: 0.55))
        }

        func test_badgeColor_nilScore() {
            let badge = MealScoreBadge(score: nil, onTap: {})
            XCTAssertEqual(badge.badgeColor, .secondary)
        }

        // MARK: - Regression: Stub Score (50%) Shown Before AI Analysis

        /// Guards the fix in JournalBlockView that passes `nil` when `!meal.isAIAnalyzed`.
        /// AILogicService returns 0.5 synchronously while the user types; that stub must
        /// never appear as "50%" in the badge.
        func test_regression_unanalyzedMeal_badgeHiddenWhenNilPassed() {
            let badge = MealScoreBadge(score: nil, onTap: {})
            XCTAssertFalse(badge.shouldDisplay, "Badge must be hidden before AI analysis completes")
            XCTAssertEqual(badge.formattedScore, "", "No score text should appear for unanalyzed meals")
        }

        /// Documents the pre-fix behaviour: passing 0.5 directly (the stub score) would
        /// show "50%" because 0.5 > 0 satisfies shouldDisplay.
        /// JournalBlockView must pass nil, not meal.healthScore, when !isAIAnalyzed.
        func test_regression_stubScore_wouldDisplayIfPassedDirectly() {
            let badge = MealScoreBadge(score: 0.5, onTap: {})
            XCTAssertTrue(
                badge.shouldDisplay,
                "0.5 stub score satisfies shouldDisplay — caller must gate on isAIAnalyzed"
            )
            XCTAssertEqual(badge.formattedScore, "50%", "Passing 0.5 directly produces the '50%' bug")
        }

        // MARK: - Edge Cases

        func test_badgeVisible_scoreBoundaryAt0_55() {
            let badge = MealScoreBadge(score: 0.55, onTap: {})
            XCTAssertTrue(badge.shouldDisplay)
            XCTAssertEqual(badge.formattedScore, "55%")
            XCTAssertEqual(badge.badgeColor, Color(red: 0.5, green: 0.6, blue: 0.7))
        }

        func test_badgeVisible_scoreBoundaryAt0_35() {
            let badge = MealScoreBadge(score: 0.35, onTap: {})
            XCTAssertTrue(badge.shouldDisplay)
            XCTAssertEqual(badge.formattedScore, "35%")
            XCTAssertEqual(badge.badgeColor, Color(red: 0.65, green: 0.6, blue: 0.55))
        }
    }
#endif
