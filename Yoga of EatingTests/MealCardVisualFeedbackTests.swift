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

        // MARK: - MealCardBackground: Accent Bar Wiring (Phase 3)

        // Note: MealCardBackground no longer renders a score-based stroke border.
        // The left accent bar is driven by MealType.displayColor (passed from JournalBlockView).
        // The score-based tint overlay is handled via MealCardFeedback.tintColor / tintOpacity.
        // Tests for borderWidth/borderColor on MealCardFeedback are omitted because
        // those model fields are not rendered by MealCardBackground.

        func test_mealCardBackground_accentBarUsesDisplayColor_breakfast() {
            // Given: breakfast meal type
            let color = MealType.breakfast.displayColor
            // Then: orange — passed as mealTypeColor into MealCardBackground
            XCTAssertTrue(self.colorMatches(color, .orange))
        }

        func test_mealCardBackground_accentBarUsesDisplayColor_lunch() {
            let color = MealType.lunch.displayColor
            XCTAssertTrue(self.colorMatches(color, .green))
        }

        func test_mealCardBackground_accentBarUsesDisplayColor_dinner() {
            let color = MealType.dinner.displayColor
            XCTAssertTrue(self.colorMatches(color, .purple))
        }

        func test_mealCardBackground_accentBarUsesDisplayColor_snacks() {
            let color = MealType.snacks.displayColor
            XCTAssertTrue(self.colorMatches(color, .pink))
        }

        func test_mealCardBackground_accentBarUsesDisplayColor_drinks() {
            let color = MealType.drinks.displayColor
            XCTAssertTrue(self.colorMatches(color, .blue))
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

        // MARK: - Edge Cases (Tint Boundary Scores)

        func test_feedback_zeroScore_hasOrangeTint() {
            // Given: Zero score — minimum health
            let feedback = MealCardFeedback(score: 0.0, mealTypeColor: .blue)
            // Then: warning tint (not green)
            XCTAssertTrue(self.colorMatches(feedback.tintColor, .mealFeedbackWarning))
        }

        func test_feedback_perfectScore_hasGreenTint() {
            // Given: Perfect score (1.0)
            let feedback = MealCardFeedback(score: 1.0, mealTypeColor: .blue)
            // Then: positive tint
            XCTAssertTrue(self.colorMatches(feedback.tintColor, .mealFeedbackPositive))
        }

        // MARK: - Left Accent Bar Theme Constants (Phase 3)

        func test_mealCard_accentBarWidth_matchesTheme() {
            XCTAssertEqual(AppTheme.MealCard.accentBarWidth, 3.0, accuracy: 0.01)
        }

        func test_mealCard_accentBarCornerRadius_isPositive() {
            XCTAssertGreaterThan(AppTheme.MealCard.accentBarCornerRadius, 0)
        }
    }
#endif
