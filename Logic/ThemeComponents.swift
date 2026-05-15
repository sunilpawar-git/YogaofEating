import SwiftUI

// MARK: - Component-specific AppTheme tokens

extension AppTheme {
    // MARK: - Meal Card

    enum MealCard {
        static let borderColor = Color(.systemGray4)
        static let borderWidth: CGFloat = 1.0
        static let background = Color(.secondarySystemBackground)
        static let accentBarWidth: CGFloat = 3.0
        static let accentBarCornerRadius: CGFloat = 2.0
    }

    // MARK: - Score Badge

    enum ScoreBadge {
        static let background = Color(.secondarySystemBackground)
        static let textColor = Color.secondary
        static let borderWidth: CGFloat = 1.2

        static func colorForScore(_ score: Double) -> Color {
            if score > 0.75 {
                Color(red: 0.5, green: 0.65, blue: 0.55)
            } else if score >= 0.55 {
                Color(red: 0.5, green: 0.6, blue: 0.7)
            } else if score >= ScoringThresholds.unhealthy {
                Color(red: 0.65, green: 0.6, blue: 0.55)
            } else {
                Color(red: 0.55, green: 0.55, blue: 0.55)
            }
        }
    }

    // MARK: - Score Category Colors

    enum ScoreColors {
        static let excellent = Color.green
        static let good = Color.teal
        static let moderate = Color.orange
        static let poor = Color.red
    }

    // MARK: - Animation

    enum Animation {
        static let standardDuration: Double = 0.3
        static let standard = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let breathingPulse = SwiftUI.Animation
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        static let breathingScale: CGFloat = 1.04
    }

    // MARK: - Background Glow

    enum Background {
        static let glowOpacity: Double = 0.08
        static let glowBlurRadius: CGFloat = 60
        static let glowSize: CGFloat = 200
        static let glowOffsetX: CGFloat = -100
        static let glowOffsetY: CGFloat = -150
    }

    // MARK: - Timeline

    enum Timeline {
        static let spineOpacity: Double = 0.18
        static let spineWidth: CGFloat = 1.5
        static let fastingSignificantFillOpacity: Double = 0.08
        static let fastingSignificantColor: Color = .green
        static let fastingDefaultColor: Color = .secondary.opacity(0.8)
    }

    // MARK: - Wellbeing Dimension Colors

    enum Dimension {
        static let physicalLoad = Color.orange.opacity(0.85)
        static let emotionalTone = Color.teal.opacity(0.85)
        static let cognitiveClarity = Color.purple.opacity(0.8)
        static let behavioralMomentum = Color.green.opacity(0.85)

        static func color(for dimension: WellbeingDimension) -> Color {
            switch dimension {
            case .physicalLoad: self.physicalLoad
            case .emotionalTone: self.emotionalTone
            case .cognitiveClarity: self.cognitiveClarity
            case .behavioralMomentum: self.behavioralMomentum
            }
        }
    }

    // MARK: - Text Entry

    enum TextEntry {
        static let maxCharacters: Int = ValidationLimits.universal
        // Note: text-entry settle delay lives in TimingConstants.textEntryDebounceNanoseconds
    }

    // MARK: - Calorie Pill

    /// Visual constants for the CaloriePillView.
    /// Single source of truth — no hardcoded colors in views or models.
    enum CaloriePill {
        // MARK: Fill Colors (liquid fill behind pill text)

        /// < 70% consumed — on track (muted sage green, matching app's minimalist palette)
        static let fillOnTrack = Color(red: 0.35, green: 0.62, blue: 0.47).opacity(0.55)

        /// 70–95% consumed — approaching goal (warm amber)
        static let fillApproaching = Color(red: 0.85, green: 0.60, blue: 0.20).opacity(0.55)

        /// > 95% consumed — at or over goal (muted coral)
        static let fillOver = Color(red: 0.80, green: 0.36, blue: 0.36).opacity(0.55)

        // MARK: Pill Track (unfilled portion background)

        /// Adaptive background for the unfilled portion of the pill capsule.
        /// `Color.primary` resolves to near-white in dark mode and near-black in light mode,
        /// so the pill outline is always visible regardless of the app's color scheme.
        static let pillBackground = Color.primary.opacity(0.10)

        // MARK: Text Colors

        /// Primary text color on pill — adapts to light/dark mode.
        /// White in dark mode (readable over dark bg + colored fill);
        /// near-black in light mode (readable over white bg + light colored fill).
        static let textPrimary = Color.primary

        /// Flame icon tint color
        static let flameIcon = Color(red: 0.90, green: 0.55, blue: 0.15)

        /// Remaining-calories positive color (muted sage green — matches fillOnTrack family)
        static let colorRemaining = Color(red: 0.20, green: 0.62, blue: 0.35)

        // MARK: Pill Geometry

        /// Maximum width for the calorie pill (design spec: ~220pt)
        static let pillMaxWidth: CGFloat = 220

        /// Vertical padding inside the pill (above/below the label text)
        static let pillVerticalPadding: CGFloat = 3

        /// Horizontal padding inside the pill — minimal so it hugs the text
        static let pillHorizontalPadding: CGFloat = 7

        // Note: colour-band thresholds (approachingFraction, overFraction) are business logic.
        // SSOT: ScoringThresholds.caloriePillApproachingFraction / caloriePillOverFraction.
    }

    // MARK: - Date Context

    /// Constants used by `DateContextProvider` to determine contextual date subtext.
    enum DateContext {
        /// Hour of day (24 h) before which "Good morning" is shown when no sleep is logged.
        static let morningHourThreshold: Int = 10
    }

    // MARK: - Cloud Sync / Restore Status Backgrounds

    /// Background tint colours for the sync and restore status pills in `SettingsCloudSection`.
    enum CloudSync {
        /// Idle / not-started state.
        static let idleBackground = Color.blue.opacity(0.1)
        /// Active (syncing / restoring) state.
        static let activeBackground = Color.blue.opacity(0.2)
        /// Success state.
        static let successBackground = Color.green.opacity(0.15)
        /// Error state.
        static let errorBackground = Color.red.opacity(0.1)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.cardBackground)
            )
    }

    func subtleBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
    }

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
