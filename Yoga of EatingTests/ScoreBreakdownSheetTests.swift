#if canImport(XCTest)
    import SwiftUI
    import XCTest
    @testable import Yoga_of_Eating

    final class ScoreBreakdownSheetTests: XCTestCase {
        // MARK: - ScoreReasoningGenerator Tests

        func test_scoreReasoningGenerator_generatesReasoning_forHighProteinMeal() {
            // Given: A high protein meal
            let meal = Meal(
                mealType: .snacks,
                items: ["Whey Protein shake"],
                healthScore: 0.8,
                isAIAnalyzed: true
            )

            // When
            let reasoning = ScoreReasoningGenerator.generateReasoning(for: meal)

            // Then: Should generate reasoning text
            XCTAssertFalse(reasoning.isEmpty, "Should generate reasoning for analyzed meal")
        }

        func test_scoreReasoningGenerator_generatesReasoning_forUnhealthyMeal() {
            // Given: An unhealthy meal
            let meal = Meal(
                mealType: .snacks,
                items: ["Large pizza", "Soda", "Ice cream"],
                healthScore: 0.25,
                isAIAnalyzed: true
            )

            // When
            let reasoning = ScoreReasoningGenerator.generateReasoning(for: meal)

            // Then: Should generate reasoning text
            XCTAssertFalse(reasoning.isEmpty, "Should generate reasoning for unhealthy meal")
        }

        func test_scoreReasoningGenerator_returnsEmptyString_forEmptyMeal() {
            // Given: An empty meal
            let meal = Meal(
                mealType: .lunch,
                items: [],
                healthScore: 0.0,
                isAIAnalyzed: false
            )

            // When
            let reasoning = ScoreReasoningGenerator.generateReasoning(for: meal)

            // Then: Should return empty string
            XCTAssertTrue(reasoning.isEmpty, "Should return empty for empty meal")
        }

        func test_scoreReasoningGenerator_returnsEmptyString_whenNotAnalyzed() {
            // Given: A meal not yet analyzed
            let meal = Meal(
                mealType: .lunch,
                items: ["Chicken salad"],
                healthScore: 0.5, // Default score
                isAIAnalyzed: false
            )

            // When
            let reasoning = ScoreReasoningGenerator.generateReasoning(for: meal)

            // Then: Should return empty string (not analyzed yet)
            XCTAssertTrue(reasoning.isEmpty, "Should return empty for non-analyzed meal")
        }

        func test_scoreReasoningGenerator_includesMealItems_inReasoning() {
            // Given: A specific meal
            let meal = Meal(
                mealType: .breakfast,
                items: ["Oatmeal", "Banana"],
                healthScore: 0.85,
                isAIAnalyzed: true
            )

            // When
            let reasoning = ScoreReasoningGenerator.generateReasoning(for: meal)

            // Then: Reasoning should reference the meal items
            XCTAssertTrue(
                reasoning.lowercased().contains("oatmeal") ||
                    reasoning.lowercased().contains("banana") ||
                    reasoning.lowercased().contains("breakfast"),
                "Reasoning should reference meal content or type"
            )
        }

        // MARK: - Score Category Tests

        func test_scoreReasoningGenerator_categorizes_excellentScore() {
            // Given: Excellent score (>= 0.8)
            let meal = Meal(
                mealType: .lunch,
                items: ["Grilled salmon", "Steamed vegetables"],
                healthScore: 0.9,
                isAIAnalyzed: true
            )

            // When
            let category = ScoreReasoningGenerator.scoreCategory(for: meal.healthScore)

            // Then
            XCTAssertEqual(category, .excellent)
        }

        func test_scoreReasoningGenerator_categorizes_goodScore() {
            // Given: Good score (0.65 - 0.8)
            let meal = Meal(
                mealType: .lunch,
                items: ["Chicken sandwich"],
                healthScore: 0.7,
                isAIAnalyzed: true
            )

            // When
            let category = ScoreReasoningGenerator.scoreCategory(for: meal.healthScore)

            // Then
            XCTAssertEqual(category, .good)
        }

        func test_scoreReasoningGenerator_categorizes_moderateScore() {
            // Given: Moderate score (0.35 - 0.65)
            let meal = Meal(
                mealType: .dinner,
                items: ["Pasta with cheese"],
                healthScore: 0.5,
                isAIAnalyzed: true
            )

            // When
            let category = ScoreReasoningGenerator.scoreCategory(for: meal.healthScore)

            // Then
            XCTAssertEqual(category, .moderate)
        }

        func test_scoreReasoningGenerator_categorizes_poorScore() {
            // Given: Poor score (< 0.35)
            let meal = Meal(
                mealType: .snacks,
                items: ["Chips", "Candy"],
                healthScore: 0.2,
                isAIAnalyzed: true
            )

            // When
            let category = ScoreReasoningGenerator.scoreCategory(for: meal.healthScore)

            // Then
            XCTAssertEqual(category, .poor)
        }

        // MARK: - Formatted Score Tests

        func test_scoreBreakdownViewModel_formattedScore() {
            // Given: A meal with specific score
            let meal = Meal(
                mealType: .lunch,
                items: ["Salad"],
                healthScore: 0.75,
                isAIAnalyzed: true
            )

            // When
            let viewModel = ScoreBreakdownViewModel(meal: meal)

            // Then
            XCTAssertEqual(viewModel.formattedScore, "75%")
        }

        // MARK: - Meal Description Tests

        func test_scoreBreakdownViewModel_mealDescription() {
            // Given: A meal with multiple items
            let meal = Meal(
                mealType: .breakfast,
                items: ["Eggs", "Toast", "Orange juice"],
                healthScore: 0.7,
                isAIAnalyzed: true
            )

            // When
            let viewModel = ScoreBreakdownViewModel(meal: meal)

            // Then: Should join items with commas
            XCTAssertTrue(viewModel.mealDescription.contains("Eggs"))
            XCTAssertTrue(viewModel.mealDescription.contains("Toast"))
            XCTAssertTrue(viewModel.mealDescription.contains("Orange juice"))
        }

        func test_scoreBreakdownViewModel_mealDescription_handlesEmptyItems() {
            // Given: A meal with no items
            let meal = Meal(
                mealType: .lunch,
                items: [],
                healthScore: 0.5,
                isAIAnalyzed: false
            )

            // When
            let viewModel = ScoreBreakdownViewModel(meal: meal)

            // Then: Should return empty or placeholder
            XCTAssertTrue(viewModel.mealDescription.isEmpty || viewModel.mealDescription == "No items logged")
        }
    }
#endif
