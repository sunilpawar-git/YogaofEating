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

    // MARK: - Meal Card Theme

    enum MealCard {
        /// Subtle border color for meal cards (adapts to light/dark)
        static let borderColor = Color(.systemGray4)

        /// Standard thin border width for minimal UI
        static let borderWidth: CGFloat = 1.0

        /// Card background with subtle tint
        static let background = Color(.secondarySystemBackground)

        /// Width of the left-edge accent bar in points (Phase 3).
        /// 3pt is visible for scanning but does not dominate the card.
        static let accentBarWidth: CGFloat = 3.0

        /// Corner radius of the left-edge accent bar (Phase 3).
        static let accentBarCornerRadius: CGFloat = 2.0
    }

    // MARK: - Score Badge Theme

    enum ScoreBadge {
        /// Background color for the score badge
        static let background = Color(.secondarySystemBackground)

        /// Text color for the score badge
        static let textColor = Color.secondary
    }

    // MARK: - Score Category Colors

    enum ScoreColors {
        /// Excellent score color (green)
        static let excellent = Color.green

        /// Good score color (teal)
        static let good = Color.teal

        /// Moderate score color (orange)
        static let moderate = Color.orange

        /// Poor score color (red)
        static let poor = Color.red
    }

    // MARK: - Animation

    enum Animation {
        /// Standard spring animation
        static let standard = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)

        /// Quick animation for micro-interactions
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)

        /// Slow animation for emphasis
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)

        /// Gentle breathing animation used for the smiley when no meals are logged.
        /// Repeats indefinitely, autoreverses for a smooth in-out pulse.
        static let breathingPulse = SwiftUI.Animation
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)

        /// Scale factor applied at peak of the breathing pulse.
        /// 1.04 is perceptible but not distracting — a subtle ambient invitation.
        static let breathingScale: CGFloat = 1.04
    }

    // MARK: - Background (Phase 5)

    /// Constants for the ambient background glow behind the date header.
    enum Background {
        /// Opacity of the warm orange glow ellipse.
        /// 0.08 is perceptible against white/cream — subtle but present.
        static let glowOpacity: Double = 0.08

        /// Blur radius for the glow ellipse. Tighter than the old 100pt.
        static let glowBlurRadius: CGFloat = 60

        /// Size of the glow ellipse in points (width and height).
        static let glowSize: CGFloat = 200

        /// Horizontal offset of the glow (negative = left).
        static let glowOffsetX: CGFloat = -100

        /// Vertical offset of the glow (negative = up, towards date header).
        static let glowOffsetY: CGFloat = -150
    }

    // MARK: - Timeline (Phase 1)

    /// Visual constants for the day timeline spine and fasting connectors.
    enum Timeline {
        /// Opacity of the vertical timeline spine line.
        /// 0.18 ensures legibility on white/cream backgrounds while staying minimal.
        static let spineOpacity: Double = 0.18

        /// Width of the vertical timeline spine line in points.
        static let spineWidth: CGFloat = 1.5

        /// Fill opacity for the significant-fasting capsule background (green wash).
        static let fastingSignificantFillOpacity: Double = 0.08

        /// Text/stroke color for significant fasting badges (12h+).
        static let fastingSignificantColor: Color = .green

        /// Text/stroke color for default (non-significant) fasting badges.
        static let fastingDefaultColor: Color = .secondary.opacity(0.8)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies the standard card style
    func cardStyle() -> some View {
        self
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.cardBackground)
            )
    }

    /// Applies a subtle border style
    func subtleBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

    /// Applies pill/capsule style
    func pillStyle() -> some View {
        self
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(
                Capsule()
                    .fill(AppTheme.cardBackground)
            )
    }
}
