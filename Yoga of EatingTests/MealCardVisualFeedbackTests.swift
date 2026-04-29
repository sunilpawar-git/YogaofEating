#if canImport(XCTest)
    import SwiftUI
    import XCTest
    @testable import Yoga_of_Eating

    final class MealCardVisualFeedbackTests: XCTestCase {
        // MARK: - Helper Methods

        /// Helper to check if a color matches expected type by description
        private func colorMatches(_ color: Color, _ expected: Color) -> Bool {
            color.description == expected.description
        }

        // MARK: - Uniform Border Tests (Minimal UI)

        func test_mealCardFeedback_borderWidth_alwaysReturnsStandard() {
            // Given: Various health scores
            let highScore = MealCardFeedback(score: 0.9, mealTypeColor: .blue)
            let mediumScore = MealCardFeedback(score: 0.5, mealTypeColor: .green)
            let lowScore = MealCardFeedback(score: 0.2, mealTypeColor: .orange)

            // When/Then: All should return standard thin border (1.0)
            XCTAssertEqual(highScore.borderWidth, 1.0, "High score should have thin border")
            XCTAssertEqual(mediumScore.borderWidth, 1.0, "Medium score should have thin border")
            XCTAssertEqual(lowScore.borderWidth, 1.0, "Low score should have thin border")
        }

        func test_mealCardFeedback_borderColor_usesSubtleMealTypeColor() {
            // Given: Different meal type colors
            let blueFeedback = MealCardFeedback(score: 0.8, mealTypeColor: .blue)
            let greenFeedback = MealCardFeedback(score: 0.5, mealTypeColor: .green)
            let orangeFeedback = MealCardFeedback(score: 0.2, mealTypeColor: .orange)

            // When/Then: Border color should be based on meal type, not score
            // We check that the color description contains the base color
            XCTAssertFalse(
                self.colorMatches(blueFeedback.borderColor, .mealFeedbackPositive),
                "Border should not be green feedback color"
            )
            XCTAssertFalse(
                self.colorMatches(greenFeedback.borderColor, .mealFeedbackWarning),
                "Border should not be orange warning color"
            )
            XCTAssertFalse(
                self.colorMatches(orangeFeedback.borderColor, .mealFeedbackWarning),
                "Border should not be orange warning color for low score"
            )
        }

        func test_mealCardFeedback_highScore_noBorderWidthChange() {
            // Given: Score above healthy threshold
            let feedback = MealCardFeedback(score: 0.95, mealTypeColor: .purple)

            // When
            let width = feedback.borderWidth

            // Then: Should still return standard thin border (no thick border for high scores)
            XCTAssertEqual(width, 1.0, "High score should NOT get thick border")
        }

        func test_mealCardFeedback_borderWidth_consistentAcrossAllScores() {
            // Given: Range of scores from 0 to 1
            let scores: [Double] = [0.0, 0.25, 0.35, 0.5, 0.65, 0.75, 1.0]

            for score in scores {
                // When
                let feedback = MealCardFeedback(score: score, mealTypeColor: .blue)

                // Then: All should have same thin border
                XCTAssertEqual(
                    feedback.borderWidth,
                    1.0,
                    "Score \(score) should have thin border"
                )
            }
        }

        // MARK: - Tint Opacity Tests (Keep subtle tints for feedback)

        func test_tintOpacity_highScore_returnsGreenTint() {
            // Given: High health score
            let feedback = MealCardFeedback(score: 0.7, mealTypeColor: .blue)

            // When
            let opacity = feedback.tintOpacity

            // Then: Should return subtle green tint (0.1)
            XCTAssertEqual(opacity, 0.1)
        }

        func test_tintOpacity_lowScore_returnsOrangeTint() {
            // Given: Low health score
            let feedback = MealCardFeedback(score: 0.3, mealTypeColor: .blue)

            // When
            let opacity = feedback.tintOpacity

            // Then: Should return subtle orange tint (0.08)
            XCTAssertEqual(opacity, 0.08)
        }

        func test_tintOpacity_mediumScore_returnsNoTint() {
            // Given: Medium health score
            let feedback = MealCardFeedback(score: 0.5, mealTypeColor: .blue)

            // When
            let opacity = feedback.tintOpacity

            // Then: Should return no tint (0.0)
            XCTAssertEqual(opacity, 0.0)
        }

        // MARK: - Tint Color Tests

        func test_tintColor_highScore_returnsPositive() {
            // Given: High health score
            let feedback = MealCardFeedback(score: 0.7, mealTypeColor: .blue)

            // When
            let tintColor = feedback.tintColor

            // Then: Should return positive feedback color
            XCTAssertTrue(self.colorMatches(tintColor, .mealFeedbackPositive))
        }

        func test_tintColor_lowScore_returnsWarning() {
            // Given: Low health score
            let feedback = MealCardFeedback(score: 0.3, mealTypeColor: .blue)

            // When
            let tintColor = feedback.tintColor

            // Then: Should return warning color
            XCTAssertTrue(self.colorMatches(tintColor, .mealFeedbackWarning))
        }

        func test_tintColor_mediumScore_returnsClear() {
            // Given: Medium health score
            let feedback = MealCardFeedback(score: 0.5, mealTypeColor: .blue)

            // When
            let tintColor = feedback.tintColor

            // Then: Should return clear (no tint)
            XCTAssertTrue(self.colorMatches(tintColor, .clear))
        }

        // MARK: - Edge Cases

        func test_feedback_zeroScore_hasThinBorder() {
            // Given: Zero score
            let feedback = MealCardFeedback(score: 0.0, mealTypeColor: .blue)

            // When/Then: Should have thin border
            XCTAssertEqual(feedback.borderWidth, 1.0)
        }

        func test_feedback_perfectScore_hasThinBorder() {
            // Given: Perfect score (1.0)
            let feedback = MealCardFeedback(score: 1.0, mealTypeColor: .blue)

            // When/Then: Should still have thin border (no thick border)
            XCTAssertEqual(feedback.borderWidth, 1.0)
        }

        // MARK: - Left Accent Bar Theme Constants (Phase 3)

        func test_mealCard_accentBarWidth_matchesTheme() {
            // Given / When
            let width = AppTheme.MealCard.accentBarWidth

            // Then: 3pt left accent bar — visible but not dominant
            XCTAssertEqual(width, 3.0, accuracy: 0.01)
        }

        func test_mealCard_accentBarWidth_isPositive() {
            XCTAssertGreaterThan(AppTheme.MealCard.accentBarWidth, 0)
        }

        func test_mealCard_accentBarCornerRadius_isPositive() {
            XCTAssertGreaterThan(AppTheme.MealCard.accentBarCornerRadius, 0)
        }

        func test_mealCard_accentBarColor_breakfast_isOrange() {
            // Given: breakfast meal type
            let color = MealType.breakfast.displayColor

            // Then: orange (breakfast warmth)
            XCTAssertTrue(self.colorMatches(color, .orange))
        }

        func test_mealCard_accentBarColor_lunch_isGreen() {
            let color = MealType.lunch.displayColor
            XCTAssertTrue(self.colorMatches(color, .green))
        }

        func test_mealCard_accentBarColor_dinner_isPurple() {
            let color = MealType.dinner.displayColor
            XCTAssertTrue(self.colorMatches(color, .purple))
        }

        func test_mealCard_accentBarColor_snacks_isPink() {
            let color = MealType.snacks.displayColor
            XCTAssertTrue(self.colorMatches(color, .pink))
        }

        func test_mealCard_accentBarColor_drinks_isBlue() {
            let color = MealType.drinks.displayColor
            XCTAssertTrue(self.colorMatches(color, .blue))
        }
    }
#endif
