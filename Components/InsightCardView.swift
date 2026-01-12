import SwiftUI

/// A card that displays an AI-generated insight to the user.
/// Shown in the morning after sleep quality is logged.
struct InsightCardView: View {
    // MARK: - Properties

    /// The insight to display
    let insight: DailyInsight

    /// Callback when the card is dismissed
    var onDismiss: (() -> Void)?

    // MARK: - Private

    @State private var isExpanded = true
    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        self.colorScheme == .dark
            ? Color(.systemGray6)
            : Color(.systemBackground)
    }

    private var accentGradient: LinearGradient {
        switch self.insight.insightType {
        case .foodSleep:
            LinearGradient(
                colors: [.indigo.opacity(0.3), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .mindsetFeeling:
            LinearGradient(
                colors: [.teal.opacity(0.3), .cyan.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pattern:
            LinearGradient(
                colors: [.orange.opacity(0.3), .yellow.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .encouragement:
            LinearGradient(
                colors: [.green.opacity(0.3), .mint.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and dismiss
            HStack {
                // Insight type icon and label
                HStack(spacing: 8) {
                    Image(systemName: self.insight.insightType.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentColor)

                    Text(self.insight.insightType.displayName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Dismiss button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        self.onDismiss?()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            // Insight text
            Text(self.insight.insightText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // Confidence indicator (subtle)
            if self.insight.confidence > 0.7 {
                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10))
                    Text("Based on your patterns")
                        .font(.system(size: 11, design: .rounded))
                }
                .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(self.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(self.accentGradient)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .accessibilityLabel("Insight: \(self.insight.insightText)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#if DEBUG
    #Preview("Food & Sleep") {
        InsightCardView(
            insight: DailyInsight(
                date: Date(),
                insightText: "Your late dinner yesterday (pasta at 9pm) may have affected your sleep. Try eating dinner earlier for better rest.",
                insightType: .foodSleep,
                confidence: 0.85
            )
        ) {
            print("Dismissed")
        }
        .padding()
    }

    #Preview("Encouragement") {
        InsightCardView(
            insight: DailyInsight(
                date: Date(),
                insightText: "Great job maintaining healthy eating patterns this week! Your energy levels seem to reflect your balanced choices. 💪",
                insightType: .encouragement,
                confidence: 0.9
            )
        )
        .padding()
    }
#endif
