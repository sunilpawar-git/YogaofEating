import SwiftUI

/// A bottom sheet that displays the unified daily insight.
/// Appears when user taps the peekaboo star button or smiley long-press.
struct InsightBottomSheet: View {
    let insight: DailyInsight
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var accentGradient: LinearGradient {
        switch self.insight.correlationCards.first?.category {
        case .foodToSleep, .foodDebt:
            LinearGradient(
                colors: [.indigo.opacity(0.15), .purple.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .focusToFeeling, .intentionFollowthrough, .journalTonePrediction:
            LinearGradient(
                colors: [.teal.opacity(0.15), .cyan.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .timingPattern, .sleepRecoveryCarryover, .sleepMismatch:
            LinearGradient(
                colors: [.orange.opacity(0.15), .yellow.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        default:
            LinearGradient(
                colors: [.green.opacity(0.15), .mint.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    self.headerSection
                    self.dominantInsightSection
                    if !self.insight.correlationCards.isEmpty {
                        self.correlationCardsSection
                    }
                    if self.insight.confidence > ScoringThresholds.high {
                        self.confidenceSection
                    }
                    self.gotItButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(self.colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 20).fill(self.accentGradient))
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: self.insight.correlationCards.first?.category.icon ?? "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.accentColor)
                Text(Strings.Insight.dailyTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            Spacer()
            Text(self.insight.headline)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.secondary.opacity(0.1)))
        }
    }

    // MARK: - Dominant Insight

    private var dominantInsightSection: some View {
        Text(self.insight.dominantInsight)
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .foregroundColor(.primary)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Correlation Cards (replaces references)

    private var correlationCardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.Insight.basedOnPatterns)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            ForEach(self.insight.correlationCards.prefix(3)) { card in
                HStack(spacing: 8) {
                    Image(systemName: card.category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text(card.observation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
    }

    // MARK: - Confidence

    private var confidenceSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkle").font(.system(size: 12))
            Text(Strings.Insight.basedOnPatterns).font(.caption)
        }
        .foregroundColor(.secondary.opacity(0.8))
    }

    // MARK: - Got It

    private var gotItButton: some View {
        Button(action: {
            SensoryService.shared.playNudge(style: .light)
            self.onDismiss()
        }) {
            Text(Strings.Insight.gotIt)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.accentColor))
        }
        .buttonStyle(.plain)
        .padding(.top, 10)
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        InsightBottomSheet(
            insight: DailyInsight(
                date: Date(),
                headline: Strings.Insight.Headline.strong,
                dimensions: .neutral,
                dominantInsight: "Your regular meal timing is linked to better sleep. On days you finish eating before 8pm, your next morning feels noticeably better.",
                correlationCards: [
                    CorrelationCard(
                        category: .foodToSleep,
                        observation: "Earlier dinners → better sleep",
                        confidence: 0.85,
                        dataPoints: []
                    )
                ],
                nudge: ActionableNudge(
                    suggestion: Strings.Insight.Nudge.defaultSuggestion,
                    reasoning: Strings.Insight.Nudge.defaultReasoning
                ),
                causalExplanation: "Food timing is the driver.",
                textSignals: [], confidence: 0.85
            ),
            onDismiss: {}
        )
        .padding()
    }
#endif
