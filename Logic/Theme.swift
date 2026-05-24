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

    // MARK: - Text Colors

    /// Primary text color
    static let textPrimary = Color.primary

    /// Secondary text color
    static let textSecondary = Color.secondary

    /// Muted text color
    static let textMuted = Color.secondary.opacity(0.7)

    // MARK: - Correlation Category Colors

    /// Amber tone for food-debt correlation cards
    static let foodDebtColor = Color.orange.opacity(0.9)

    /// Soft purple for journal-tone prediction cards
    static let journalToneColor = Color.purple.opacity(0.7)

    // MARK: - Border Colors

    /// Subtle border color
    static let borderSubtle = Color.primary.opacity(0.08)

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

    // MARK: - Layout

    /// Screen-level layout constants. Centralise these to avoid magic numbers in views
    /// and to allow design-system-wide adjustments in one place.
    enum Layout {
        /// Height of the invisible spacer anchoring the scroll-to-bottom proxy.
        static let bottomScrollBuffer: CGFloat = 100

        /// Size of the smiley add-button on the today timeline.
        /// Kept in the 80–100pt range to preserve emotional presence without dominating the screen.
        static let smileyButtonSize: CGFloat = 92
    }
}
