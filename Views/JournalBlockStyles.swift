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

/// A reusable card background with material effect, visual feedback overlay,
/// and a left-edge accent bar coloured by meal type.
///
/// The accent bar provides instant meal-type scanning down the left edge of the
/// timeline without colouring the whole card. The score-based full-border is
/// intentionally removed — the subtle tint overlay carries score feedback instead.
struct MealCardBackground: View {
    let feedback: MealCardFeedback

    /// Meal type colour used for the left accent bar.
    /// Pass `meal.mealType.displayColor` from the containing view.
    let mealTypeColor: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.4))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .fill(self.feedback.tintColor.opacity(self.feedback.tintOpacity))
            }
            .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
            .overlay(alignment: .leading) {
                self.leftAccentBar
            }
    }

    /// 3pt left-edge bar in the meal type's colour.
    /// Inset from top and bottom edges to float within the card.
    private var leftAccentBar: some View {
        RoundedRectangle(cornerRadius: AppTheme.MealCard.accentBarCornerRadius)
            .fill(self.mealTypeColor)
            .frame(width: AppTheme.MealCard.accentBarWidth)
            .padding(.vertical, AppTheme.Spacing.small)
            .padding(.leading, 0)
            .accessibilityHidden(true)
    }
}

// MARK: - Breathing Content View

/// A breathing animation placeholder shown while waiting
struct BreathingContentView: View {
    var body: some View {
        Text(Strings.Components.breathe)
            .font(.system(.subheadline, design: .serif))
            .italic()
            .foregroundColor(.secondary)
    }
}

// MARK: - Preview

#Preview("Card Background - Healthy") {
    MealCardBackground(
        feedback: MealCardFeedback(score: 0.8, mealTypeColor: .green),
        mealTypeColor: .green
    )
    .frame(width: 300, height: 150)
    .padding()
}

#Preview("Card Background - Unhealthy") {
    MealCardBackground(
        feedback: MealCardFeedback(score: 0.3, mealTypeColor: .orange),
        mealTypeColor: .orange
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
        .accessibilityLabel(Strings.Accessibility.addMealFromRecent)
        .accessibilityHint(Strings.Accessibility.addMealFromRecentHint)
    }
}
