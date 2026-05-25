import SwiftUI

// MARK: - BriefingDetailView Section Subviews

extension BriefingDetailView {
    func correlationCardRow(_ card: CorrelationCard) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: card.category.icon)
                .font(.title3)
                .foregroundStyle(AppTheme.CorrelationCard.color(for: card.category))
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

    func confidenceBar(_ value: Double) -> some View {
        HStack(spacing: 4) {
            GeometryReader { geo in
                Capsule()
                    .fill(.quaternary)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(
                                value > 0.7
                                    ? AppTheme.CorrelationCard.highConfidenceColor
                                    : AppTheme.CorrelationCard.lowConfidenceColor
                            )
                            .frame(width: geo.size.width * value)
                    }
            }
            .frame(height: 4)

            Text("\(Int(value * 100))%")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    var weeklyTrendSection: some View {
        if let trend = self.insight.weeklyTrend {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Briefing.weeklyTrendSection)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .kerning(1)

                HStack(spacing: 20) {
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
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
            Text(label)
                .font(FontTheme.caption)
                .foregroundStyle(.secondary)
        }
    }
}
