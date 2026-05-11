import SwiftUI

/// Centralized theme configuration for the app.
/// Provides consistent colors, spacing, typography, and styling.
/// Follows a hybrid approach: warmer accents with clean white/grey backgrounds.
enum AppTheme {
    // MARK: - Background Colors

    /// Main background color (clean white/off-white)
    static let background = Color(.systemBackground)

    /// Card/container background (subtle grey)
    static let cardBackground = Color(.systemGray6).opacity(0.5)

    /// Sheet/modal background
    static let sheetBackground = Color(.systemBackground)

    /// Secondary background for subtle sections
    static let secondaryBackground = Color(.secondarySystemBackground)

    // MARK: - Accent Colors

    /// Warm accent for positive actions (orange-tinted)
    static let warmAccent = Color.orange.opacity(0.15)

    /// Success accent (green)
    static let successAccent = Color.green.opacity(0.15)

    /// Warning accent (yellow-orange)
    static let warningAccent = Color.yellow.opacity(0.2)

    /// Primary accent (app tint)
    static let primaryAccent = Color.accentColor

    // MARK: - Text Colors

    /// Primary text color
    static let textPrimary = Color.primary

    /// Secondary text color
    static let textSecondary = Color.secondary

    /// Muted text color
    static let textMuted = Color.secondary.opacity(0.7)

    // MARK: - Border Colors

    /// Subtle border color
    static let borderSubtle = Color.primary.opacity(0.08)

    /// Medium border color
    static let borderMedium = Color.primary.opacity(0.12)

    /// Accent border color
    static let borderAccent = Color.accentColor.opacity(0.3)

    // MARK: - Spacing

    enum Spacing {
        /// Extra small spacing (4pt)
        static let xSmall: CGFloat = 4

        /// Small spacing (8pt)
        static let small: CGFloat = 8

        /// Medium spacing (16pt)
        static let medium: CGFloat = 16

        /// Large spacing (24pt)
        static let large: CGFloat = 24

        /// Extra large spacing (32pt)
        static let xLarge: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        /// Small corner radius (8pt)
        static let small: CGFloat = 8

        /// Medium corner radius (12pt)
        static let medium: CGFloat = 12

        /// Large corner radius (16pt)
        static let large: CGFloat = 16

        /// Pill/capsule radius
        static let pill: CGFloat = 100
    }

    // MARK: - Typography

    enum Typography {
        /// Large title font
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)

        /// Title font
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)

        /// Headline font
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)

        /// Body font
        static let body = Font.system(size: 17, weight: .regular, design: .default)

        /// Callout font
        static let callout = Font.system(size: 16, weight: .regular, design: .default)

        /// Subheadline font
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)

        /// Footnote font
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)

        /// Caption font
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
    }

    // MARK: - Shadows

    enum Shadow {
        /// Subtle shadow for cards
        static let subtle = Color.black.opacity(0.05)

        /// Medium shadow for elevated elements
        static let medium = Color.black.opacity(0.1)
    }
}
