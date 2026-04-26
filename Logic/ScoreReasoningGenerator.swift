import Foundation

/// Represents the health score category for a meal
enum ScoreCategory: String, Equatable {
    case excellent = "Excellent"
    case good = "Good"
    case moderate = "Moderate"
    case poor = "Poor"

    /// Emoji representation of the category
    var emoji: String {
        switch self {
        case .excellent: "🌟"
        case .good: "👍"
        case .moderate: "😐"
        case .poor: "⚠️"
        }
    }

    /// Color name for the category (semantic)
    var colorName: String {
        switch self {
        case .excellent: "green"
        case .good: "teal"
        case .moderate: "orange"
        case .poor: "red"
        }
    }
}

/// Generates human-readable reasoning for meal health scores
enum ScoreReasoningGenerator {
    // MARK: - Score Category

    /// Determines the score category based on health score
    /// - Parameter score: Health score (0.0 to 1.0)
    /// - Returns: Score category
    static func scoreCategory(for score: Double) -> ScoreCategory {
        switch score {
        case 0.8...:
            .excellent
        case 0.65..<0.8:
            .good
        case 0.35..<0.65:
            .moderate
        default:
            .poor
        }
    }

    // MARK: - Reasoning Generation

    /// Generates a human-readable reasoning for the meal's health score
    /// - Parameter meal: The meal to generate reasoning for
    /// - Returns: Reasoning string, empty if not applicable
    static func generateReasoning(for meal: Meal) -> String {
        // Don't generate reasoning for non-analyzed meals
        guard meal.isAIAnalyzed else { return "" }

        // Don't generate reasoning for empty meals
        guard !meal.items.isEmpty else { return "" }

        let category = self.scoreCategory(for: meal.healthScore)
        let mealDescription = meal.items.joined(separator: ", ")

        return self.generateReasoningText(
            category: category,
            mealType: meal.mealType,
            items: meal.items,
            mealDescription: mealDescription
        )
    }

    // MARK: - Private Helpers

    private static func generateReasoningText(
        category: ScoreCategory,
        mealType: MealType,
        items: [String],
        mealDescription _: String
    ) -> String {
        switch category {
        case .excellent:
            self.generateExcellentReasoning(mealType: mealType, items: items)
        case .good:
            self.generateGoodReasoning(mealType: mealType, items: items)
        case .moderate:
            self.generateModerateReasoning(mealType: mealType, items: items)
        case .poor:
            self.generatePoorReasoning(mealType: mealType, items: items)
        }
    }

    private static func generateExcellentReasoning(mealType: MealType, items: [String]) -> String {
        let itemsText = items.prefix(2).joined(separator: " and ")
        return "\(itemsText) is a nutritious choice for "
            + "\(mealType.displayName.lowercased()). Great balance of nutrients!"
    }

    private static func generateGoodReasoning(mealType: MealType, items: [String]) -> String {
        let itemsText = items.prefix(2).joined(separator: " and ")
        return "\(itemsText) provides good nutritional value. A solid \(mealType.displayName.lowercased()) choice."
    }

    private static func generateModerateReasoning(mealType _: MealType, items: [String]) -> String {
        let itemsText = items.prefix(2).joined(separator: " and ")
        return "\(itemsText) has mixed nutritional value. Consider adding more vegetables or protein."
    }

    private static func generatePoorReasoning(mealType _: MealType, items: [String]) -> String {
        let itemsText = items.prefix(2).joined(separator: " and ")
        return "\(itemsText) is high in processed ingredients. Try healthier alternatives for better nutrition."
    }
}
