import Foundation
import SwiftUI

// MARK: - Recent Meals & Copy Meal (Repeat Meal Feature)

extension MainViewModel {
    /// Returns unique meals from the past 3 days for quick-add suggestions.
    /// Deduplicates by normalized items content (lowercased, sorted).
    /// Returns max 8 meals, most recent first.
    func getRecentUniqueMeals() -> [Meal] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var allMeals: [Meal] = []

        for daysAgo in 1...3 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            if let snapshot = self.historicalService.getSnapshot(for: date) {
                allMeals.append(contentsOf: snapshot.meals)
            }
        }

        var seenKeys = Set<String>()
        var uniqueMeals: [Meal] = []

        let sortedMeals = allMeals.sorted { $0.timestamp > $1.timestamp }

        for meal in sortedMeals {
            guard !meal.items.isEmpty else { continue }

            let normalizedKey = meal.items
                .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                .sorted()
                .joined(separator: "|")

            if !seenKeys.contains(normalizedKey) {
                seenKeys.insert(normalizedKey)
                uniqueMeals.append(meal)
            }

            if uniqueMeals.count >= 8 {
                break
            }
        }

        return uniqueMeals
    }

    /// Copies a historical meal to today with a fresh ID and current timestamp.
    /// Preserves meal type and items from the original meal.
    func copyMealToToday(_ meal: Meal) {
        self.checkAndResetIfNewDay()

        let newMeal = Meal(
            id: UUID(),
            timestamp: Date(),
            mealType: meal.mealType,
            items: meal.items,
            healthScore: meal.healthScore,
            isAIAnalyzed: false
        )

        withAnimation(.spring()) {
            self.meals.append(newMeal)
        }
        self.saveData()

        let copiedId = newMeal.id
        self.aiCoordinator.analyzeIfNeeded(
            mealId: copiedId,
            items: newMeal.items,
            in: self.makeAnalysisContext(mealId: copiedId)
        )
    }
}
