import SwiftUI

/// Full-screen detail sheet for the morning briefing.
/// Receives the DailyBriefing via parameter (data-contract pattern).
struct BriefingDetailView: View {
    let insight: DailyInsight
    var onDismiss: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    self.headlineSection
                    self.correlationCardsSection
                    self.nudgeSection
                    self.weeklyTrendSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Strings.Briefing.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Briefing.doneButton) { self.onDismiss?() }
                }
            }
        }
    }

    // MARK: - Headline

    @ViewBuilder
    private var headlineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sun.and.horizon.fill")
                    .foregroundStyle(AppTheme.Briefing.sunAccent)
                Text(self.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(self.insight.headline)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Correlation Cards

    @ViewBuilder
    private var correlationCardsSection: some View {
        if !self.insight.correlationCards.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(Strings.Briefing.patternsSection)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .kerning(1)

                ForEach(self.insight.correlationCards) { card in
                    self.correlationCardRow(card)
                }
            }
        }
    }

    // MARK: - Nudge

    private var nudgeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Briefing.nudgeSection)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .kerning(1)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(AppTheme.Briefing.nudgeAccent)
                    Text(self.insight.nudge.suggestion)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Text(self.insight.nudge.reasoning)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let meal = self.insight.nudge.relatedMeal {
                    Text(Strings.Briefing.relatedMealPrefix + meal)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: self.insight.date)
    }

    func trendIcon(_ direction: TrendDirection) -> String {
        switch direction {
        case .improving: "arrow.up.right"
        case .declining: "arrow.down.right"
        case .steady: "arrow.right"
        }
    }
}

#Preview {
    BriefingDetailView(
        insight: DailyInsight(
            date: Date(),
            headline: "Protein lunches power your best afternoons",
            dimensions: .neutral,
            dominantInsight: "Your eating patterns are improving your energy.",
            correlationCards: [
                CorrelationCard(
                    category: .foodToMood,
                    observation: "Days with healthier meals end with better mood",
                    confidence: 0.85, dataPoints: []
                ),
                CorrelationCard(
                    category: .timingPattern,
                    observation: "Regular meal timing improves your sleep quality",
                    confidence: 0.72, dataPoints: []
                )
            ],
            nudge: ActionableNudge(
                suggestion: "Try repeating Tuesday's grilled chicken salad",
                reasoning: "It correlated with your best afternoon this week"
            ),
            weeklyTrend: WeeklyTrendSnippet(
                averageFoodScore: 0.72,
                averageSleepQuality: 0.68,
                daysLogged: 6,
                trendDirection: .improving
            ),
            causalExplanation: "Physical load is the driver.",
            textSignals: [],
            confidence: 0.8
        )
    )
}
