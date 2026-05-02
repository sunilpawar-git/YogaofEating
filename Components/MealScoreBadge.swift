import SwiftUI

/// A tappable badge displaying a meal's health score as a percentage.
/// Features:
/// - Score-based coloring for visual feedback (excellent/good/moderate/low)
/// - Visible border for clarity and tappability affordance
/// - Subtle press animation to indicate interactivity
/// - Icon hint (→) to signal tappable action
struct MealScoreBadge: View {
    // MARK: - Properties

    /// The health score (0.0 to 1.0), nil if not yet analyzed
    let score: Double?

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

    /// Badge color based on score value — uses muted, minimalist palette
    /// - Excellent (>0.75): Muted sage green
    /// - Good (0.55-0.75): Muted slate blue
    /// - Moderate (0.35-0.55): Muted warm grey
    /// - Low (<0.35): Muted stone grey
    var badgeColor: Color {
        guard let score else { return .secondary }
        if score > 0.75 {
            return Color(red: 0.5, green: 0.65, blue: 0.55) // Sage green
        } else if score >= 0.55 {
            return Color(red: 0.5, green: 0.6, blue: 0.7) // Slate blue
        } else if score >= 0.35 {
            return Color(red: 0.65, green: 0.6, blue: 0.55) // Warm grey
        } else {
            return Color(red: 0.55, green: 0.55, blue: 0.55) // Stone grey
        }
    }

    // MARK: - Body

    var body: some View {
        if self.shouldDisplay {
            Button(action: self.onTap) {
                HStack(spacing: 3) {
                    Text(self.formattedScore)
                        .font(FontTheme.textEntry(size: 12, weight: .semibold))

                    Image(systemName: "chevron.right")
                        .font(FontTheme.textEntry(size: 9, weight: .semibold))
                }
                .foregroundStyle(Color(.systemBackground))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(self.badgeColor)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(self.badgeColor.opacity(0.7), lineWidth: 1.2)
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
        }
    }
}

// MARK: - Preview

#Preview("Score Badge - High Score") {
    MealScoreBadge(score: 0.85, onTap: {})
}

#Preview("Score Badge - Medium Score") {
    MealScoreBadge(score: 0.55, onTap: {})
}

#Preview("Score Badge - Low Score") {
    MealScoreBadge(score: 0.25, onTap: {})
}

#Preview("Score Badge - No Score") {
    MealScoreBadge(score: nil, onTap: {})
}
