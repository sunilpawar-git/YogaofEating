import SwiftUI

// MARK: - CaloriePill AppTheme tokens

extension AppTheme {
    /// Visual constants for the CaloriePillView.
    /// Single source of truth — no hardcoded colors in views or models.
    enum CaloriePill {
        // MARK: - Fill Colors (liquid fill behind pill text)

        /// < 70% consumed — on track (muted sage green, matching app's minimalist palette)
        static let fillOnTrack = Color(red: 0.35, green: 0.62, blue: 0.47).opacity(0.55)

        /// 70–95% consumed — approaching goal (warm amber)
        static let fillApproaching = Color(red: 0.85, green: 0.60, blue: 0.20).opacity(0.55)

        /// > 95% consumed — at or over goal (muted coral)
        static let fillOver = Color(red: 0.80, green: 0.36, blue: 0.36).opacity(0.55)

        // MARK: - Text Colors

        /// Primary text color on pill (white — readable over fill + material)
        static let textPrimary = Color.white

        /// Flame icon tint color
        static let flameIcon = Color(red: 0.90, green: 0.55, blue: 0.15)

        /// Remaining-calories positive color (muted sage green — matches fillOnTrack family)
        static let colorRemaining = Color(red: 0.20, green: 0.62, blue: 0.35)

        // MARK: - Pill Geometry

        /// Fixed pill height in points
        static let pillHeight: CGFloat = 34

        /// Maximum pill width — keeps the pill compact and centered above "TAP TO LOG"
        static let pillMaxWidth: CGFloat = 220

        /// Horizontal padding inside the pill
        static let pillHorizontalPadding: CGFloat = 14

        // MARK: - Threshold fractions (SSOT for color-band boundaries)

        /// Below this fraction → fillOnTrack
        static let approachingThreshold: Double = 0.70

        /// At or above this fraction → fillOver
        static let overThreshold: Double = 0.95
    }
}
