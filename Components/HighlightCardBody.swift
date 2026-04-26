import SwiftUI

/// Card body for the Highlight (evening review) module.
/// Shows plan vs execution summary, feeling badge, insight, and end-of-day CTA.
struct HighlightCardBody: View {
    let dataSource: ModuleCardDataSource

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            self.planVsExecutionRow

            if let feeling = self.dataSource.cardFeeling {
                self.feelingBadge(feeling)
            }

            if let insight = self.dataSource.cardInsightText {
                self.insightPreview(insight)
            }

            if self.dataSource.shouldShowEndOfDayPrompt {
                self.endOfDayButton
            }
        }
    }
}

// MARK: - Subviews

private extension HighlightCardBody {
    var planVsExecutionRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "chart.bar")
                .font(.caption)
            Text(Strings.Home.planVsExecution)
                .font(.subheadline)

            Spacer()

            if let intention = self.dataSource.cardIntention {
                Text(intention)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .foregroundColor(.primary)
    }

    func feelingBadge(_ feeling: ReflectionFeeling) -> some View {
        HStack(spacing: 4) {
            Text(feeling.emoji)
            Text(feeling.displayName)
                .font(.subheadline)
        }
        .foregroundColor(AppTheme.ModuleColors.highlight)
    }

    func insightPreview(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
    }

    var endOfDayButton: some View {
        Button {
            self.dataSource.triggerEndOfDay()
        } label: {
            Label(Strings.Home.endOfDayButton, systemImage: "moon.stars")
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppTheme.ModuleColors.highlight)
        }
    }
}
