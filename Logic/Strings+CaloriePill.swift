import Foundation

// MARK: - Strings: CaloriePill

extension Strings {
    /// String resources for the CaloriePillView and CalorieDetailSheet.
    /// All user-facing calorie text lives here — enables future localisation without view edits.
    enum CaloriePill {
        // MARK: - Unit

        /// The calorie unit label displayed throughout the pill and detail sheet.
        /// Capital "Cal" = 1 kilocalorie — the consumer convention used by Apple Health,
        /// MyFitnessPal, and all world-class health apps.
        static let calUnit = "Cal"

        // MARK: - Pill Text

        /// Leading decorative chevron flanking the pill content.
        static let pillLeadingChevron = "‹"

        /// Trailing decorative chevron flanking the pill content.
        static let pillTrailingChevron = "›"

        /// Full fraction display with emojis, e.g. "🔥1,250 Cal /🎯2,250 Cal"
        static func consumedOfTarget(consumed: String, target: String) -> String {
            "🔥\(consumed) \(self.calUnit) /🎯\(target) \(self.calUnit)"
        }

        /// Consumed-only display (no TDEE) — used in detail sheet rows, e.g. "1,250 Cal"
        static func consumedOnly(_ formatted: String) -> String {
            "\(formatted) \(self.calUnit)"
        }

        /// Shown when the user has not set up a health profile.
        static let setupProfile = "Set up profile"

        /// Pill-only setup-prompt line, e.g. "🔥1,250 Cal  ·  Set up profile"
        static func consumedWithSetupPrompt(_ formatted: String) -> String {
            "🔥\(formatted) \(self.calUnit)  ·  \(self.setupProfile)"
        }

        // MARK: - Accessibility

        /// Accessibility label when both consumed and TDEE are known.
        static func accessibilityLabel(consumed: String, tdee: String) -> String {
            "\(consumed) of \(tdee) \(self.calUnit) consumed today"
        }

        /// Accessibility label when TDEE is unknown.
        static func accessibilityLabelConsumedOnly(consumed: String) -> String {
            "\(consumed) \(self.calUnit) consumed today. Tap to set up profile."
        }

        // MARK: - Detail Sheet

        /// Heading for the CalorieDetailSheet.
        static let detailHeading = "Daily Energy"

        /// Row label for consumed calories in the detail sheet.
        static let rowConsumed = "Consumed"

        /// Row label for the daily goal (TDEE) in the detail sheet — shown when no breakdown is available.
        static let rowGoal = "Goal"

        /// Row label for the profile-only base goal in the "Base + Exercise" breakdown.
        static let rowGoalBase = "Base Goal"

        /// Row label for exercise calories added on top of the base goal.
        static let rowGoalExercise = "Exercise"

        /// Row label for the total goal (base + exercise) in the breakdown.
        static let rowGoalTotal = "Total Goal"

        /// Exercise calorie value prefix, e.g. "+151 Cal"
        static func exerciseCalories(_ formatted: String) -> String {
            "+\(formatted) \(self.calUnit)"
        }

        /// Row label for remaining calories in the detail sheet.
        static let rowRemaining = "Remaining"

        /// Row label when the user has exceeded their goal.
        static let rowOver = "Over Goal"

        /// Accessibility label for the progress bar in the detail sheet.
        static let progressBarAccessibilityLabel = "Daily calorie progress"

        /// Section heading for the per-meal breakdown.
        static let sectionByMeal = "By meal"

        /// Estimated calorie annotation prefix, e.g. "~620 Cal"
        static func estimatedCalories(_ formatted: String) -> String {
            "~\(formatted) \(self.calUnit)"
        }

        // MARK: - Goal Breakdown Section

        /// Section heading when the goal is decomposed into base + exercise.
        static let sectionGoalBreakdown = "How your goal is set"
    }
}
