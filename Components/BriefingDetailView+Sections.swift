import SwiftUI

// MARK: - BriefingDetailView Section Subviews

extension BriefingDetailView {
    func correlationCardRow(_ card: CorrelationCard) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.CorrelationCard.color(for: card.category).opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: card.category.icon)
                    .font(.callout)
                    .foregroundStyle(AppTheme.CorrelationCard.color(for: card.category))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(card.category.displayName)
                    .font(FontTheme.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(card.observation)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

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

    func confidenceBar(_ value: Double) -> some View {
        HStack(spacing: 6) {
            ProgressView(value: value)
                .progressViewStyle(.linear)
                .tint(
                    value > 0.7
                        ? AppTheme.CorrelationCard.highConfidenceColor
                        : AppTheme.CorrelationCard.lowConfidenceColor
                )

            Text("\(Int(value * 100))%")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
    }

    @ViewBuilder
    var dimensionBarsSection: some View {
        if let breakdown = self.liveBreakdown {
            VStack(alignment: .leading, spacing: 12) {
                Text(Strings.Briefing.todaysSnapshotSection)
                    .font(FontTheme.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                VStack(spacing: 14) {
                    ForEach(WellbeingDimension.allCases, id: \.self) { dimension in
                        WellbeingDimensionBar(
                            dimension: dimension,
                            value: dimension.value(in: breakdown.dimensions),
                            isDominant: dimension == breakdown.dominantDimension,
                            mealCount: breakdown.mealCount
                        )
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
    }

    @ViewBuilder
    var weeklyTrendSection: some View {
        if let trend = self.insight.weeklyTrend {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Briefing.weeklyTrendSection)
                    .font(FontTheme.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                HStack(spacing: 0) {
                    self.trendStat(
                        label: Strings.Briefing.TrendLabel.food,
                        value: "\(Int(trend.averageFoodScore * 100))%",
                        icon: "fork.knife"
                    )
                    self.trendStat(
                        label: Strings.Briefing.TrendLabel.sleep,
                        value: "\(Int(trend.averageSleepQuality * 100))%",
                        icon: "moon.zzz.fill"
                    )
                    self.trendStat(
                        label: Strings.Briefing.TrendLabel.days,
                        value: "\(trend.daysLogged)",
                        icon: "calendar"
                    )
                    self.trendStat(
                        label: Strings.Briefing.TrendLabel.trend,
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

    func trendStat(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
            Text(label)
                .font(FontTheme.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
