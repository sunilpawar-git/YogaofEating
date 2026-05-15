import SwiftUI

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

    /// Total calories burned so far today (resting + active). `nil` when either value is unavailable.
    var totalBurned: Int? {
        guard let basal = self.basalCalories, let active = self.activeCalories else { return nil }
        return Int((basal + active).rounded())
    }

    /// Whether the "Base Goal + Exercise = Total Goal" breakdown should be displayed.
    /// Requires a profile base and non-zero exercise calories — otherwise a single "Goal" row suffices.
    var hasGoalBreakdown: Bool {
        guard self.profileBaseTdee != nil else { return false }
        return (self.activeCalories ?? 0) > 0
    }

    /// Fraction of TDEE consumed, clamped to [0, 1]. Returns 0.0 when TDEE is nil.
    var progressFraction: Double {
        guard let tdee, tdee > 0 else { return 0.0 }
        return min(1.0, Double(self.consumed) / Double(tdee))
    }

    /// Fill color for the progress bar — mirrors `CaloriePillData.fillColor` thresholds.
    /// Thresholds are SSOT in `ScoringThresholds`; colors are SSOT in `AppTheme.CaloriePill`.
    var progressFillColor: Color {
        guard self.tdee != nil else { return AppTheme.CaloriePill.fillOnTrack }
        if self.progressFraction >= ScoringThresholds.caloriePillOverFraction {
            return AppTheme.CaloriePill.fillOver
        } else if self.progressFraction >= ScoringThresholds.caloriePillApproachingFraction {
            return AppTheme.CaloriePill.fillApproaching
        }
        return AppTheme.CaloriePill.fillOnTrack
    }

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
