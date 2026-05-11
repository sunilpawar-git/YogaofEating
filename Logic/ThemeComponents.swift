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
        /// Settle delay (500 ms) used in Highlight/Reflect text-entry async Tasks.
        /// Intentionally separate from any meal-entry pipeline constant.
        static let debounceNanoseconds: UInt64 = 500_000_000
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
