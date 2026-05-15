import SwiftUI

/// A tappable badge displaying a meal's health score as a percentage.
/// Features:
/// - Meal-type color for visual cohesion with the type tag and timestamp pill
/// - Subtle shadow for tappability affordance
/// - Subtle press animation to indicate interactivity
/// - Icon hint (→) to signal tappable action
struct MealScoreBadge: View {
    // MARK: - Properties

    /// The health score (0.0 to 1.0), nil if not yet analyzed
    let score: Double?

    /// Color sourced from the meal type — unifies all three card pills visually
    let mealTypeColor: Color

    /// Callback when badge is tapped (shows score breakdown sheet)
    let onTap: () -> Void

    // MARK: - Local State

    @State private var isPressed: Bool = false

    // MARK: - Computed Properties

    /// Whether the badge should be displayed
    var shouldDisplay: Bool {
        guard let score else { return false }
        return score > 0
    }

    /// Formatted score as percentage string (e.g., "80%")
    var formattedScore: String {
        guard let score, score > 0 else { return "" }
        return "\(Int(score * 100))%"
    }

    // MARK: - Body

    var body: some View {
        if self.shouldDisplay {
            Button(action: self.onTap) {
                HStack(spacing: 3) {
                    Text(self.formattedScore)
                        .font(FontTheme.textEntry(size: 12, weight: .semibold))
                        .contentTransition(.numericText())

                    Image(systemName: "chevron.right")
                        .font(FontTheme.textEntry(size: 9, weight: .semibold))
                }
                .foregroundStyle(Color(.systemBackground))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(self.mealTypeColor)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(self.mealTypeColor.opacity(0.7), lineWidth: 1.2)
                )
                .shadow(
                    color: AppTheme.MealCard.pillShadowColor,
                    radius: AppTheme.MealCard.pillShadowRadius,
                    y: AppTheme.MealCard.pillShadowY
                )
            }
            .buttonStyle(.plain)
            .scaleEffect(self.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: self.isPressed)
            .onLongPressGesture(minimumDuration: 0.01, perform: {}, onPressingChanged: { pressing in
                self.isPressed = pressing
            })
            .accessibilityLabel("Health score: \(self.formattedScore)")
            .accessibilityHint("Tap to see detailed score breakdown and nutrition analysis")
            .transition(.opacity)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: self.shouldDisplay)
        }
    }
}

// MARK: - Preview

#Preview("Score Badge - High Score") {
    MealScoreBadge(score: 0.85, mealTypeColor: .green, onTap: {})
}

#Preview("Score Badge - Medium Score") {
    MealScoreBadge(score: 0.55, mealTypeColor: .orange, onTap: {})
}

#Preview("Score Badge - Low Score") {
    MealScoreBadge(score: 0.25, mealTypeColor: .purple, onTap: {})
}

#Preview("Score Badge - No Score") {
    MealScoreBadge(score: nil, mealTypeColor: .blue, onTap: {})
}
