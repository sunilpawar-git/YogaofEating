import SwiftUI

// MARK: - MealType Visual Extensions

extension MealType {
    /// Returns the associated color for this meal type
    var displayColor: Color {
        switch self {
        case .breakfast: .orange
        case .lunch: .green
        case .dinner: .purple
        case .snacks: .pink
        case .drinks: .blue
        }
    }

    /// Returns the SF Symbol icon name for this meal type
    var iconName: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "fork.knife"
        case .dinner: "moon.stars.fill"
        case .snacks: "popcorn.fill"
        case .drinks: "cup.and.saucer.fill"
        }
    }
}

// MARK: - Card Background View

/// A reusable card background with material effect and visual feedback overlay.
/// Used by JournalBlockView for consistent meal card styling.
struct MealCardBackground: View {
    let feedback: MealCardFeedback

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.4))
            }
            .overlay {
                // Subtle tint overlay for visual feedback
                RoundedRectangle(cornerRadius: 16)
                    .fill(self.feedback.tintColor.opacity(self.feedback.tintOpacity))
            }
            .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(self.feedback.borderColor, lineWidth: self.feedback.borderWidth)
            )
    }
}

// MARK: - AI Sparkle Indicator (Deprecated)

/// Sparkle indicator shown when AI analysis completes
/// - Note: Replaced by `MealScoreBadge` which shows the actual score percentage
@available(*, deprecated, message: "Use MealScoreBadge instead for displaying meal health scores")
struct AISparkleIndicator: View {
    let isAnalyzed: Bool

    var body: some View {
        if self.isAnalyzed {
            Text("✨")
                .font(.system(size: 14))
                .transition(.opacity.combined(with: .scale))
                .animation(.easeIn(duration: 0.3), value: self.isAnalyzed)
                .accessibilityLabel("AI analyzed")
                .accessibilityHint("This meal has been analyzed by AI")
        }
    }
}

// MARK: - Breathing Content View

/// A breathing animation placeholder shown while waiting
struct BreathingContentView: View {
    var body: some View {
        Text("Breathe...")
            .font(.system(.subheadline, design: .serif))
            .italic()
            .foregroundColor(.secondary)
    }
}

// MARK: - Preview

#Preview("Card Background - Healthy") {
    MealCardBackground(
        feedback: MealCardFeedback(score: 0.8, mealTypeColor: .green)
    )
    .frame(width: 300, height: 150)
    .padding()
}

#Preview("Card Background - Unhealthy") {
    MealCardBackground(
        feedback: MealCardFeedback(score: 0.3, mealTypeColor: .orange)
    )
    .frame(width: 300, height: 150)
    .padding()
}

// MARK: - Recent Meals Add Button

/// A small circular "+" button for adding from recent meals
struct RecentMealsAddButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            SensoryService.shared.playNudge(style: .light)
            self.action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.7))
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}
