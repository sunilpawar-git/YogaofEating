import Foundation

/// Encapsulates button visibility logic for meal cards.
/// Controls which action buttons appear based on editing state and available content.
///
/// Button visibility rules:
/// - Done button: shown only when focused AND has content (user is actively typing)
/// - Recent meals: shown only when NOT focused AND has recent meals (ready to add)
/// - Timestamp: always shown (critical for user awareness of meal time)
///
/// This ensures never more than 2 buttons appear simultaneously.
struct MealActionButtonVisibility {
    let isFocused: Bool
    let hasContent: Bool
    let hasRecentMeals: Bool

    /// Done button (checkmark) shown only when focused and has content.
    var shouldShowDoneButton: Bool {
        self.isFocused && self.hasContent
    }

    /// Recent meals (+) button shown only when unfocused and has recent meals.
    var shouldShowRecentMealsButton: Bool {
        !self.isFocused && self.hasRecentMeals
    }

    /// Timestamp button always shown (critical for user awareness of meal time).
    var shouldShowTimestampButton: Bool {
        true
    }
}
