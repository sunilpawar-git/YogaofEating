import SwiftUI

/// A compact card that displays the unified daily insight.
/// Shown in the morning after sleep quality is logged.
struct InsightCardView: View {
    let insight: DailyInsight
    var onDismiss: (() -> Void)?

    @State private var isExpanded = true
    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        self.colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }

    private var accentGradient: LinearGradient {
        switch self.insight.correlationCards.first?.category {
        case .foodToSleep, .foodDebt:
            LinearGradient(
                colors: [.indigo.opacity(0.3), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .focusToFeeling, .intentionFollowthrough:
            LinearGradient(
                colors: [.teal.opacity(0.3), .cyan.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .timingPattern, .sleepRecoveryCarryover:
            LinearGradient(
                colors: [.orange.opacity(0.3), .yellow.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            LinearGradient(
                colors: [.green.opacity(0.3), .mint.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: self.insight.correlationCards.first?.category.icon ?? "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentColor)
                    Text(self.insight.headline)
                        .font(FontTheme.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                Spacer()
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

            Text(self.insight.dominantInsight)
                .font(FontTheme.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if self.insight.confidence > ScoringThresholds.high {
                HStack(spacing: 4) {
                    Image(systemName: "sparkle").font(.system(size: 10))
                    Text(Strings.Insight.basedOnPatterns).font(.system(size: 11, design: .rounded))
                }
                .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(self.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 16).fill(self.accentGradient))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .accessibilityLabel("Insight: \(self.insight.dominantInsight)")
    }
}

#if DEBUG
    #Preview {
        InsightCardView(
            insight: DailyInsight(
                date: Date(),
                headline: Strings.Insight.Headline.steady,
                dimensions: .neutral,
                dominantInsight: "Your late dinner yesterday may have affected your sleep. Try eating dinner earlier for better rest.",
                correlationCards: [
                    CorrelationCard(
                        category: .foodToSleep,
                        observation: "Earlier dinners → better sleep",
                        confidence: 0.85,
                        dataPoints: []
                    )
                ],
                nudge: ActionableNudge(
                    suggestion: "Finish dinner by 8pm",
                    reasoning: "Correlates with deeper sleep"
                ),
                causalExplanation: "Food timing is the driver.",
                textSignals: [], confidence: 0.85
            )
        ) {}
            .padding()
    }
#endif
