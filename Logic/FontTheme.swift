import SwiftUI

/// Centralized font configuration for the Yoga of Eating app.
/// This single source of truth ensures consistent, minimalist typography across all text entry fields.
///
/// **Design Philosophy**: Uses SF Rounded (.rounded) for a warm, mindful aesthetic.
/// - Approachable and calming
/// - Perfect for wellness and mindfulness applications
/// - Maintains excellent readability across all text sizes
enum FontTheme {
    // MARK: - Text Entry Fonts

    /// Primary font for meal entry, highlights, and reflections
    /// Size: 16–17pt, Regular weight
    /// Used in: TextFields, TextEditors throughout the app
    static let textEntry = Font.system(size: 16, weight: .regular, design: .rounded)

    /// Larger text entry font for main meal input
    /// Size: 17pt, Regular weight
    static let mealEntry = Font.system(size: 17, weight: .regular, design: .rounded)

    // MARK: - Display Fonts (for non-entry text)

    /// For section headers and emphasized labels
    /// Size: 18pt, Semibold weight
    static let sectionHeader = Font.system(size: 18, weight: .semibold, design: .rounded)

    /// For body text and descriptions
    /// Size: 16pt, Regular weight
    static let body = Font.system(size: 16, weight: .regular, design: .rounded)

    /// For captions and helper text
    /// Size: 12pt, Regular weight
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)

    /// For small inline icons (e.g. flame icon in CaloriePillView)
    /// Size: 11pt, Semibold weight
    static let iconSmall = Font.system(size: 11, weight: .semibold, design: .rounded)

    // MARK: - Semantic Convenience Methods

    /// Returns the appropriate text entry font for a given context
    /// - Parameter size: Font size in points (default: 16)
    /// - Parameter weight: Font weight (default: .regular)
    static func textEntry(size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
