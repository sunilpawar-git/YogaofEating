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

        // MARK: - Border Color Tests

        func test_borderColor_highHealthScore_returnsGreen() {
            // Given: High health score (0.7)
            let feedback = MealCardFeedback(score: 0.7, mealTypeColor: .blue)

            // When
            let borderColor = feedback.borderColor

            // Then: Should return green for positive feedback
            XCTAssertTrue(self.colorMatches(borderColor, .mealFeedbackPositive))
        }

        func test_borderColor_lowHealthScore_returnsOrange() {
            // Given: Low health score (0.3)
            let feedback = MealCardFeedback(score: 0.3, mealTypeColor: .blue)

            // When
            let borderColor = feedback.borderColor

            // Then: Should return orange for warning feedback
            XCTAssertTrue(self.colorMatches(borderColor, .mealFeedbackWarning))
        }

        func test_borderColor_mediumHealthScore_returnsMealTypeColor() {
            // Given: Medium health score (0.5)
            let mealTypeColor = Color.purple
            let feedback = MealCardFeedback(score: 0.5, mealTypeColor: mealTypeColor)

            // When
            let borderColor = feedback.borderColor

            // Then: Should return meal type color for neutral
            XCTAssertTrue(self.colorMatches(borderColor, mealTypeColor))
        }

        func test_borderColor_boundaryHigh_returnsGreen() {
            // Given: Score at upper boundary (0.66)
            let feedback = MealCardFeedback(score: 0.66, mealTypeColor: .blue)

            // When
            let borderColor = feedback.borderColor

            // Then: Should return green
            XCTAssertTrue(self.colorMatches(borderColor, .mealFeedbackPositive))
        }

        func test_borderColor_boundaryLow_returnsOrange() {
            // Given: Score at lower boundary (0.34)
            let feedback = MealCardFeedback(score: 0.34, mealTypeColor: .blue)

            // When
            let borderColor = feedback.borderColor

            // Then: Should return orange
            XCTAssertTrue(self.colorMatches(borderColor, .mealFeedbackWarning))
        }

        // MARK: - Border Width Tests

        func test_borderWidth_highScore_returnsThick() {
            // Given: High health score
            let feedback = MealCardFeedback(score: 0.7, mealTypeColor: .blue)

            // When
            let width = feedback.borderWidth

            // Then: Should return thick border (3.0)
            XCTAssertEqual(width, 3.0)
        }

        func test_borderWidth_lowScore_returnsStandard() {
            // Given: Low health score
            let feedback = MealCardFeedback(score: 0.3, mealTypeColor: .blue)

            // When
            let width = feedback.borderWidth

            // Then: Should return standard border (1.0)
            XCTAssertEqual(width, 1.0)
        }

        func test_borderWidth_mediumScore_returnsStandard() {
            // Given: Medium health score
            let feedback = MealCardFeedback(score: 0.5, mealTypeColor: .blue)

            // When
            let width = feedback.borderWidth

            // Then: Should return standard border (1.0)
            XCTAssertEqual(width, 1.0)
        }

        // MARK: - Tint Opacity Tests

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

        func test_tintOpacity_boundaryHigh_returnsGreenTint() {
            // Given: Score just above threshold (0.66)
            let feedback = MealCardFeedback(score: 0.66, mealTypeColor: .blue)

            // When
            let opacity = feedback.tintOpacity

            // Then: Should return green tint
            XCTAssertEqual(opacity, 0.1)
        }

        func test_tintOpacity_boundaryLow_returnsOrangeTint() {
            // Given: Score just below threshold (0.34)
            let feedback = MealCardFeedback(score: 0.34, mealTypeColor: .blue)

            // When
            let opacity = feedback.tintOpacity

            // Then: Should return orange tint
            XCTAssertEqual(opacity, 0.08)
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

        func test_feedback_zeroScore_treatAsLow() {
            // Given: Zero score (very unhealthy)
            let feedback = MealCardFeedback(score: 0.0, mealTypeColor: .blue)

            // When
            let borderColor = feedback.borderColor
            let opacity = feedback.tintOpacity

            // Then: Should treat as low score
            XCTAssertTrue(self.colorMatches(borderColor, .mealFeedbackWarning))
            XCTAssertEqual(opacity, 0.08)
        }

        func test_feedback_perfectScore_treatAsHigh() {
            // Given: Perfect score (1.0)
            let feedback = MealCardFeedback(score: 1.0, mealTypeColor: .blue)

            // When
            let borderColor = feedback.borderColor
            let width = feedback.borderWidth

            // Then: Should treat as high score
            XCTAssertTrue(self.colorMatches(borderColor, .mealFeedbackPositive))
            XCTAssertEqual(width, 3.0)
        }

        func test_feedback_consistency_acrossProperties() {
            // Given: High score
            let highFeedback = MealCardFeedback(score: 0.8, mealTypeColor: .blue)

            // Then: All properties should be consistent
            XCTAssertTrue(self.colorMatches(highFeedback.borderColor, .mealFeedbackPositive))
            XCTAssertEqual(highFeedback.borderWidth, 3.0)
            XCTAssertEqual(highFeedback.tintOpacity, 0.1)
            XCTAssertTrue(self.colorMatches(highFeedback.tintColor, .mealFeedbackPositive))

            // Given: Low score
            let lowFeedback = MealCardFeedback(score: 0.2, mealTypeColor: .blue)

            // Then: All properties should be consistent
            XCTAssertTrue(self.colorMatches(lowFeedback.borderColor, .mealFeedbackWarning))
            XCTAssertEqual(lowFeedback.borderWidth, 1.0)
            XCTAssertEqual(lowFeedback.tintOpacity, 0.08)
            XCTAssertTrue(self.colorMatches(lowFeedback.tintColor, .mealFeedbackWarning))
        }
    }
#endif
