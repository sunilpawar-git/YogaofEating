#if canImport(XCTest)
    import SwiftUI
    import XCTest
    @testable import Yoga_of_Eating

    final class MealScoreBadgeTests: XCTestCase {
        // MARK: - Display Tests

        func test_mealScoreBadge_displaysPercentage_whenScoreExists() {
            // Given: A valid score
            let score = 0.75

            // When: Creating badge
            let badge = MealScoreBadge(score: score, onTap: {})

            // Then: Badge should be visible (score > 0)
            XCTAssertTrue(badge.shouldDisplay, "Badge should display when score exists")
        }

        func test_mealScoreBadge_hidden_whenScoreIsNil() {
            // Given: Nil score
            let score: Double? = nil

            // When: Creating badge
            let badge = MealScoreBadge(score: score, onTap: {})

            // Then: Badge should be hidden
            XCTAssertFalse(badge.shouldDisplay, "Badge should be hidden when score is nil")
        }

        func test_mealScoreBadge_hidden_whenScoreIsZero() {
            // Given: Zero score
            let score = 0.0

            // When: Creating badge
            let badge = MealScoreBadge(score: score, onTap: {})

            // Then: Badge should be hidden (no AI analysis yet)
            XCTAssertFalse(badge.shouldDisplay, "Badge should be hidden when score is zero")
        }

        // MARK: - Formatting Tests

        func test_mealScoreBadge_formatsScore_asWholeNumber() {
            // Given: Various scores
            let testCases: [(score: Double, expected: String)] = [
                (0.8, "80%"),
                (0.75, "75%"),
                (0.333, "33%"),
                (1.0, "100%"),
                (0.05, "5%")
            ]

            for testCase in testCases {
                // When
                let badge = MealScoreBadge(score: testCase.score, onTap: {})

                // Then
                XCTAssertEqual(
                    badge.formattedScore,
                    testCase.expected,
                    "Score \(testCase.score) should format as \(testCase.expected)"
                )
            }
        }

        func test_mealScoreBadge_formattedScore_returnsEmptyString_whenScoreIsNil() {
            // Given: Nil score
            let badge = MealScoreBadge(score: nil, onTap: {})

            // Then
            XCTAssertEqual(badge.formattedScore, "", "Should return empty string for nil score")
        }

        func test_mealScoreBadge_formattedScore_returnsEmptyString_whenScoreIsZero() {
            // Given: Zero score
            let badge = MealScoreBadge(score: 0.0, onTap: {})

            // Then
            XCTAssertEqual(badge.formattedScore, "", "Should return empty string for zero score")
        }

        // MARK: - Tap Action Tests

        func test_mealScoreBadge_onTap_triggersCallback() {
            // Given
            var tapCount = 0
            let badge = MealScoreBadge(score: 0.75) {
                tapCount += 1
            }

            // When: Simulating tap via callback
            badge.onTap()

            // Then
            XCTAssertEqual(tapCount, 1, "Tap callback should be triggered")
        }

        // MARK: - Edge Cases

        func test_mealScoreBadge_handles_verySmallScores() {
            // Given: Very small but non-zero score
            let badge = MealScoreBadge(score: 0.001, onTap: {})

            // Then: Should still display (score > 0)
            XCTAssertTrue(badge.shouldDisplay)
            XCTAssertEqual(badge.formattedScore, "0%") // Rounds to 0 but still shows
        }

        func test_mealScoreBadge_handles_scoresAboveOne() {
            // Given: Score above 1.0 (edge case / invalid but handle gracefully)
            let badge = MealScoreBadge(score: 1.5, onTap: {})

            // Then: Should display and format as 150%
            XCTAssertTrue(badge.shouldDisplay)
            XCTAssertEqual(badge.formattedScore, "150%")
        }

        func test_mealScoreBadge_handles_negativeScores() {
            // Given: Negative score (edge case / invalid)
            let badge = MealScoreBadge(score: -0.5, onTap: {})

            // Then: Should not display (score <= 0)
            XCTAssertFalse(badge.shouldDisplay)
        }
    }
#endif
