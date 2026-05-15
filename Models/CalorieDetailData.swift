import Foundation

// MARK: - MealCalorieEntry

/// A single meal's calorie entry for display in the detail sheet.
struct MealCalorieEntry: Equatable {
    let label: String
    let calories: Int
}

// MARK: - CalorieDetailData

/// All data needed by `CalorieDetailSheet`. Encapsulates consumed vs. goal breakdown
/// and optional Apple Watch activity data.
///
/// Constructed by `MainViewModel.calorieDetailData` — never created in a View body.
struct CalorieDetailData: Equatable {
    /// Total calories consumed from AI-analyzed meals today.
    let consumed: Int

    /// Total Daily Energy Expenditure — `nil` when no health profile is set up.
    /// Equals `profileBaseTdee + activeCalories` when both are available (MFP model).
    let tdee: Int?

    /// Profile-only TDEE before exercise is added. Non-nil only when a health profile
    /// exists — drives the "Base Goal + Exercise = Total" breakdown in the detail sheet.
    let profileBaseTdee: Int?

    /// Per-meal breakdown (only meals that have been AI-analyzed).
    let mealBreakdown: [MealCalorieEntry]

    /// Basal (resting) calories burned today from HealthKit. `nil` when unavailable.
    let basalCalories: Double?

    /// Active (exercise) calories burned today from HealthKit. `nil` when unavailable.
    let activeCalories: Double?

    /// Calories remaining to reach TDEE. Negative when over goal. `nil` when TDEE is nil.
    var remaining: Int? { self.tdee.map { $0 - self.consumed } }

    // MARK: - Initializer

    init(
        consumed: Int,
        tdee: Int?,
        profileBaseTdee: Int? = nil,
        meals: [Meal],
        basalCalories: Double? = nil,
        activeCalories: Double? = nil
    ) {
        self.consumed = consumed
        self.tdee = tdee
        self.profileBaseTdee = profileBaseTdee
        self.basalCalories = basalCalories
        self.activeCalories = activeCalories
        self.mealBreakdown = meals
            .filter { $0.estimatedCalories != nil }
            .sorted { $0.timestamp < $1.timestamp }
            .compactMap { meal in
                guard let cal = meal.estimatedCalories else { return nil }
                return MealCalorieEntry(label: meal.mealType.displayName, calories: cal)
            }
    }
}
