import SwiftUI

/// A tappable badge displaying a meal's health score as a percentage.
/// Replaces the sparkle indicator with actionable score information.
struct MealScoreBadge: View {
    // MARK: - Properties

    /// The health score (0.0 to 1.0), nil if not yet analyzed
    let score: Double?

    /// Callback when badge is tapped (shows score breakdown sheet)
    let onTap: () -> Void

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
                Text(self.formattedScore)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.ScoreBadge.textColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(AppTheme.ScoreBadge.background)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Health score: \(self.formattedScore)")
            .accessibilityHint("Tap to see score breakdown")
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
