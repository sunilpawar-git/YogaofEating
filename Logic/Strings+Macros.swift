import Foundation

// MARK: - Strings: Macros

extension Strings {
    /// String resources for the Macros section of `CalorieDetailSheet`.
    enum Macros {
        static let sectionHeader = "Macros"
        static let protein = "Protein"
        static let carbs = "Carbs"
        static let fat = "Fat"

        static func gramsLabel(_ grams: Int, partial: Bool) -> String {
            "\(partial ? "~" : "")\(grams)g"
        }

        static func accessibilityLabel(macro: String, grams: Int, partial: Bool) -> String {
            "\(partial ? "approximately " : "")\(grams) grams of \(macro)"
        }
    }
}
