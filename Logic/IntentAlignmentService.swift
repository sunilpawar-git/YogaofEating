import Foundation

/// Pure-function service that checks whether a meal aligns with
/// the user's daily eating intention via keyword matching.
/// Returns a short contextual hint or nil if no alignment can be determined.
enum IntentAlignmentService {
    // MARK: - Intention Categories

    private enum IntentionCategory {
        case lightEating
        case noSugar
        case hydration
        case moreVegetables
        case mindfulEating
    }

    private static let categoryKeywords: [(IntentionCategory, [String])] = [
        (.lightEating, ["light", "lighter", "less", "small", "portion", "moderate"]),
        (.noSugar, ["no sugar", "sugar-free", "avoid sugar", "cut sugar", "skip sugar", "no sweets"]),
        (.hydration, ["hydrat", "water", "drink more", "fluid"]),
        (.moreVegetables, ["vegetable", "veggie", "greens", "salad", "plant"]),
        (.mindfulEating, ["mindful", "slowly", "chew", "savor", "present", "awareness"])
    ]

    private static let lightFoods: Set<String> = [
        "salad", "soup", "fruit", "fruits", "vegetables", "veggies",
        "grilled", "steamed", "smoothie", "yogurt", "oatmeal"
    ]

    private static let heavyFoods: Set<String> = [
        "pizza", "burger", "fries", "fried", "cake", "ice cream",
        "pasta", "cheese", "bacon", "sausage", "chips"
    ]

    private static let sugaryFoods: Set<String> = [
        "cake", "cookie", "ice cream", "candy", "chocolate",
        "donut", "pastry", "soda", "brownie", "sugar", "syrup", "sweets"
    ]

    private static let hydrationFoods: Set<String> = [
        "water", "soup", "smoothie", "juice", "tea", "coconut water",
        "watermelon", "cucumber"
    ]

    // MARK: - Public API

    /// Returns a short alignment hint if a match is found, or nil otherwise.
    /// - Parameters:
    ///   - intention: The user's daily intention string
    ///   - mealItems: Array of food item names from a meal
    /// - Returns: A contextual hint string, or nil if no determination can be made
    static func alignmentHint(intention: String, mealItems: [String]) -> String? {
        guard !intention.isEmpty, !mealItems.isEmpty else { return nil }

        let intentionLower = intention.lowercased()
        let itemsLower = mealItems.map { $0.lowercased() }
        let joinedItems = itemsLower.joined(separator: " ")

        guard let category = detectCategory(intentionLower) else { return nil }

        switch category {
        case .lightEating:
            return self.evaluateLightEating(items: itemsLower, joinedItems: joinedItems)
        case .noSugar:
            return self.evaluateNoSugar(items: itemsLower, joinedItems: joinedItems)
        case .hydration:
            return self.evaluateHydration(items: itemsLower, joinedItems: joinedItems)
        case .moreVegetables:
            return self.evaluateVegetables(items: itemsLower, joinedItems: joinedItems)
        case .mindfulEating:
            return "Aligned with your intention — stay present while eating."
        }
    }

    // MARK: - Private Helpers

    private static func detectCategory(_ intention: String) -> IntentionCategory? {
        for (category, keywords) in self.categoryKeywords where keywords.contains(where: { intention.contains($0) }) {
            return category
        }
        return nil
    }

    private static func evaluateLightEating(items _: [String], joinedItems: String) -> String {
        let hasLight = self.lightFoods.contains { joinedItems.contains($0) }
        let hasHeavy = self.heavyFoods.contains { joinedItems.contains($0) }

        if hasHeavy {
            return "Gentle nudge: this meal may not match your lighter-eating intention."
        } else if hasLight {
            return "Aligned with your intention — nice light choice!"
        }
        return "On track with your intention."
    }

    private static func evaluateNoSugar(items _: [String], joinedItems: String) -> String {
        let hasSugary = self.sugaryFoods.contains { joinedItems.contains($0) }

        if hasSugary {
            return "Gentle nudge: this has sugary items — remember your no-sugar intention."
        }
        return "Aligned — staying on track with no sugar!"
    }

    private static func evaluateHydration(items _: [String], joinedItems: String) -> String {
        let hasHydrating = self.hydrationFoods.contains { joinedItems.contains($0) }

        if hasHydrating {
            return "Aligned — great hydrating choice!"
        }
        return "On track — don't forget to hydrate alongside this meal."
    }

    private static func evaluateVegetables(items _: [String], joinedItems: String) -> String {
        let vegKeywords: Set<String> = ["salad", "vegetable", "veggies", "greens", "spinach", "broccoli", "kale"]
        let hasVeg = vegKeywords.contains { joinedItems.contains($0) }

        if hasVeg {
            return "Aligned — great veggie choice!"
        }
        return "Gentle nudge: consider adding some vegetables to stay aligned with your intention."
    }
}
