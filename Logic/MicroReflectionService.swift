import Foundation

enum MicroReflectionService {
    /// Minimum number of rated meals before pattern insights are generated.
    private static let minimumRatedMeals = 3
    /// Satisfaction must fall more than this below hunger to flag overeating.
    private static let overeatingThreshold = 1.0
    /// Hunger below this value at dinner is flagged as "not hungry".
    private static let notHungryThreshold = 2.0

    static func insight(for meals: [Meal]) -> String? {
        let rated = meals.filter {
            $0.preHunger != nil && $0.postSatisfaction != nil
        }

        guard rated.count >= self.minimumRatedMeals else { return nil }

        if self.detectOvereatingPattern(rated) {
            return Strings.MicroReflection.overeatingHint
        }

        if self.detectNotHungryAtDinner(rated) {
            return Strings.MicroReflection.notHungryAtDinner
        }

        return nil
    }

    private static func detectOvereatingPattern(
        _ meals: [Meal]
    ) -> Bool {
        let avgHunger = meals.compactMap(\.preHunger)
            .reduce(0, +)
        let avgSatisfaction = meals.compactMap(\.postSatisfaction)
            .reduce(0, +)
        let count = Double(meals.count)

        let meanHunger = Double(avgHunger) / count
        let meanSatisfaction = Double(avgSatisfaction) / count

        return meanSatisfaction < meanHunger - Self.overeatingThreshold
    }

    private static func detectNotHungryAtDinner(
        _ meals: [Meal]
    ) -> Bool {
        let dinnerMeals = meals.filter { $0.mealType == .dinner }
        guard dinnerMeals.count >= self.minimumRatedMeals else { return false }

        let avgDinnerHunger = dinnerMeals
            .compactMap(\.preHunger)
            .reduce(0, +)

        let meanHunger = Double(avgDinnerHunger) / Double(dinnerMeals.count)
        return meanHunger < Self.notHungryThreshold
    }
}
