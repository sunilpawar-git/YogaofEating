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

        /// Full fraction display, e.g. "1,250 / 2,250 Cal"
        static func consumedOfTarget(consumed: String, target: String) -> String {
            "\(consumed) / \(target) \(self.calUnit)"
        }

        /// Consumed-only display (no TDEE), e.g. "1,250 Cal"
        static func consumedOnly(_ formatted: String) -> String {
            "\(formatted) \(self.calUnit)"
        }

        /// Shown when the user has not set up a health profile.
        static let setupProfile = "Set up profile"

        /// Full setup-prompt line shown in the pill, e.g. "1,250 Cal  ·  Set up profile"
        static func consumedWithSetupPrompt(_ formatted: String) -> String {
            "\(formatted) \(self.calUnit)  ·  \(self.setupProfile)"
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

        /// Row label for the daily goal (TDEE) in the detail sheet.
        static let rowGoal = "Goal"

        /// Row label for remaining calories in the detail sheet.
        static let rowRemaining = "Remaining"

        /// Section heading for the per-meal breakdown.
        static let sectionByMeal = "By meal"

        /// Estimated calorie annotation prefix, e.g. "~620 Cal"
        static func estimatedCalories(_ formatted: String) -> String {
            "~\(formatted) \(self.calUnit)"
        }

        // MARK: - Activity Section (Apple Watch / HealthKit)

        /// Section heading for the Apple Watch activity data.
        static let sectionActivity = "Activity"

        /// Row label for active (exercise) calories burned.
        static let rowActive = "Active"

        /// Row label for basal (resting) calories burned.
        static let rowBasal = "Resting"

        /// Row label for the total TDEE (basal + active).
        static let rowTotalTDEE = "Total Burned"
    }
}
