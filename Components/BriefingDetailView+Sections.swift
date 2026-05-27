import SwiftUI

// MARK: - BriefingDetailView Section Subviews

extension BriefingDetailView {
    // MARK: - Mood Hero

    @ViewBuilder
    var moodHeroSection: some View {
        if let breakdown = self.liveBreakdown {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    Text(breakdown.currentMood.emoji)
                        .font(.system(size: 44))
                        .accessibilityLabel(
                            String(
                                format: Strings.WellbeingBreakdown.heroEmojiAccessibilityFmt,
                                breakdown.currentMood.displayName
                            )
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(breakdown.currentMood.displayName)
                            .font(FontTheme.sectionHeader)
                        Text(breakdown.currentMood.tagline)
                            .font(FontTheme.body)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                if let text = WellbeingProgressCalculator.progressText(
                    mood: breakdown.currentMood, overall: breakdown.overallScore
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle")
                            .foregroundStyle(AppTheme.Dimension.color(for: breakdown.dominantDimension))
                        Text(text)
                            .font(FontTheme.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .accessibilityLabel(text)
                    .pillStyle()
                }
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Wellbeing Breakdown (dimension bars)

    @ViewBuilder
    var wellbeingBreakdownSection: some View {
        if let breakdown = self.liveBreakdown {
            VStack(alignment: .leading, spacing: 14) {
                Text(Strings.WellbeingBreakdown.breakdownExplainer)
                    .font(FontTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
                ForEach(WellbeingDimension.allCases, id: \.self) { dimension in
                    WellbeingDimensionBar(
                        dimension: dimension,
                        value: dimension.value(in: breakdown.dimensions),
                        isDominant: dimension == breakdown.dominantDimension,
                        mealCount: breakdown.mealCount,
                        weeklyAverage: breakdown.weeklyAverages.map { dimension.value(in: $0) },
                        hasExerciseBonus: breakdown.hasExerciseBonus && dimension == .physicalLoad
                    )
                }
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Shared helpers

    func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(FontTheme.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    // MARK: - Correlation Cards

    @ViewBuilder
    var correlationCardsSection: some View {
        if !self.insight.correlationCards.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                self.sectionLabel(Strings.Briefing.patternsSection)
                    .padding(.bottom, 16)

                ForEach(
                    Array(self.insight.correlationCards.enumerated()),
                    id: \.element.id
                ) { index, card in
                    self.correlationCardRow(card)
                    if index < self.insight.correlationCards.count - 1 {
                        Divider().padding(.vertical, 16)
                    }
                }
            }
        }
    }

    func correlationCardRow(_ card: CorrelationCard) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: card.category.icon)
                .font(.body)
                .foregroundStyle(AppTheme.CorrelationCard.color(for: card.category))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 6) {
                Text(card.category.displayName)
                    .font(FontTheme.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(card.observation)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Nudge

    var nudgeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            self.sectionLabel(Strings.Briefing.tryTodaySection)

            Text(self.insight.nudge.suggestion)
                .font(.subheadline)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)

            Text(self.insight.nudge.reasoning)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let meal = self.insight.nudge.relatedMeal {
                Text(Strings.Briefing.relatedMealPrefix + meal)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
    }

    // MARK: - Weekly Trend

    @ViewBuilder
    var weeklyTrendSection: some View {
        if let trend = self.insight.weeklyTrend {
            VStack(alignment: .leading, spacing: 8) {
                self.sectionLabel(Strings.Briefing.thisWeekSection)
                HStack(spacing: 6) {
                    Image(systemName: self.trendIcon(trend.trendDirection))
                        .font(.caption2)
                    Text(String(
                        format: Strings.Briefing.weeklyTrendFmt,
                        trend.trendDirection.rawValue.capitalized,
                        Int(trend.averageFoodScore * 100),
                        Int(trend.averageSleepQuality * 100),
                        trend.daysLogged
                    ))
                    .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }
        }
    }
}
