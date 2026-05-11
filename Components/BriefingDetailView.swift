import SwiftUI

/// Full-screen detail sheet for the morning briefing.
/// Receives the DailyBriefing via parameter (data-contract pattern).
struct BriefingDetailView: View {
    let briefing: DailyBriefing
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
            .navigationTitle("Morning Briefing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { self.onDismiss?() }
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
                    .foregroundStyle(.orange)
                Text(self.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(self.briefing.headline)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Correlation Cards

    @ViewBuilder
    private var correlationCardsSection: some View {
        if !self.briefing.correlationCards.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Patterns")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .kerning(1)

                ForEach(self.briefing.correlationCards) { card in
                    self.correlationCardRow(card)
                }
            }
        }
    }

    private func correlationCardRow(_ card: CorrelationCard) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: card.category.icon)
                .font(.title3)
                .foregroundStyle(self.colorForCategory(card.category))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(card.category.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(card.observation)
                    .font(.subheadline)

                self.confidenceBar(card.confidence)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func confidenceBar(_ value: Double) -> some View {
        HStack(spacing: 4) {
            GeometryReader { geo in
                Capsule()
                    .fill(.quaternary)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(value > 0.7 ? Color.green : .orange)
                            .frame(width: geo.size.width * value)
                    }
            }
            .frame(height: 4)

            Text("\(Int(value * 100))%")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Nudge

    private var nudgeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Nudge")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .kerning(1)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text(self.briefing.nudge.suggestion)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Text(self.briefing.nudge.reasoning)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let meal = self.briefing.nudge.relatedMeal {
                    Text("Related: \(meal)")
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

    // MARK: - Weekly Trend

    @ViewBuilder
    private var weeklyTrendSection: some View {
        if let trend = self.briefing.weeklyTrend {
            VStack(alignment: .leading, spacing: 8) {
                Text("Weekly Trend")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .kerning(1)

                HStack(spacing: 20) {
                    self.trendStat(
                        label: "Food",
                        value: "\(Int(trend.averageFoodScore * 100))%",
                        icon: "fork.knife"
                    )
                    self.trendStat(
                        label: "Sleep",
                        value: "\(Int(trend.averageSleepQuality * 100))%",
                        icon: "moon.zzz.fill"
                    )
                    self.trendStat(
                        label: "Days",
                        value: "\(trend.daysLogged)",
                        icon: "calendar"
                    )
                    self.trendStat(
                        label: "Trend",
                        value: trend.trendDirection.rawValue.capitalized,
                        icon: self.trendIcon(trend.trendDirection)
                    )
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
        }
    }

    private func trendStat(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: self.briefing.date)
    }

    private func colorForCategory(_ category: CorrelationCategory) -> Color {
        switch category {
        case .foodToSleep: .indigo
        case .foodToMood: .green
        case .focusToFeeling: .purple
        case .timingPattern: .orange
        case .foodDebt: Color(red: 0.95, green: 0.65, blue: 0.0)
        case .sleepRecoveryCarryover: .teal
        case .intentionFollowthrough: .blue
        case .journalTonePrediction: Color(red: 0.6, green: 0.4, blue: 0.8)
        case .sleepMismatch: .yellow
        case .carryOverLoad: .red
        }
    }

    private func trendIcon(_ direction: TrendDirection) -> String {
        switch direction {
        case .improving: "arrow.up.right"
        case .declining: "arrow.down.right"
        case .steady: "arrow.right"
        }
    }
}

#Preview {
    BriefingDetailView(
        briefing: DailyBriefing(
            date: Date(),
            generatedAt: Date(),
            headline: "Protein lunches power your best afternoons",
            correlationCards: [
                CorrelationCard(
                    category: .foodToMood,
                    observation: "Days with healthier meals end with better mood",
                    confidence: 0.85,
                    dataPoints: []
                ),
                CorrelationCard(
                    category: .timingPattern,
                    observation: "Regular meal timing improves your sleep quality",
                    confidence: 0.72,
                    dataPoints: []
                )
            ],
            nudge: ActionableNudge(
                suggestion: "Try repeating Tuesday's grilled chicken salad",
                reasoning: "It correlated with your best afternoon this week",
                relatedMeal: "Grilled chicken salad"
            ),
            weeklyTrend: WeeklyTrendSnippet(
                averageFoodScore: 0.72,
                averageSleepQuality: 0.68,
                daysLogged: 6,
                trendDirection: .improving
            )
        )
    )
}
