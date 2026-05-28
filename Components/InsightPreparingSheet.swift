import SwiftUI

/// Contract for InsightPreparingSheet — minimal data needed to show the preparing state.
/// No direct reference to MainViewModel (principle of least privilege).
struct InsightPreparingSheetContract {
    let weekdayName: String
    let isGenerating: Bool
    let mealCount: Int
    let averageScore: Double?
    var onRefresh: () -> Void
    var onDismiss: () -> Void
}

/// Shown in place of the stale WellbeingBreakdownSheet when the user long-presses the
/// smiley and no fresh personalized insight is ready. Shows a clear loading state when
/// generation is in progress, or a refresh prompt if generation hasn't started yet.
/// Auto-dismissed by `handleInsightGeneratedDuringFallback` when the insight arrives.
struct InsightPreparingSheet: View {
    let contract: InsightPreparingSheetContract

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                self.mainContent
                Spacer()
                if let avg = self.contract.averageScore, self.contract.mealCount > 0 {
                    self.statsPill(mealCount: self.contract.mealCount, avg: avg)
                        .padding(.bottom, AppTheme.Spacing.large)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.large)
            .navigationTitle(String(format: Strings.Briefing.insightsTitleFormat, self.contract.weekdayName))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Briefing.doneButton, action: self.contract.onDismiss)
                        .font(FontTheme.body)
                }
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if self.contract.isGenerating {
            self.loadingState
        } else {
            self.refreshPromptState
        }
    }

    private var loadingState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ProgressView()
                .scaleEffect(1.4)
                .padding(.bottom, AppTheme.Spacing.small)
            Text(String(format: Strings.Insight.Preparing.preparingTitleFmt, self.contract.weekdayName))
                .font(FontTheme.sectionHeader)
                .multilineTextAlignment(.center)
            Text(Strings.Insight.Preparing.preparingSubtitle)
                .font(FontTheme.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var refreshPromptState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "sparkles")
                .font(FontTheme.preparingIcon)
                .foregroundStyle(.secondary)
                .padding(.bottom, AppTheme.Spacing.small)
            Text(Strings.Insight.Preparing.noInsightTitle)
                .font(FontTheme.sectionHeader)
                .multilineTextAlignment(.center)
            Text(Strings.Insight.Preparing.noInsightBody)
                .font(FontTheme.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: self.contract.onRefresh) {
                Text(Strings.Insight.Preparing.refreshButton)
                    .font(FontTheme.body.weight(.semibold))
                    .padding(.horizontal, AppTheme.Spacing.large)
                    .padding(.vertical, AppTheme.Spacing.small)
                    .background(AppTheme.Briefing.refreshButtonBackground)
                    .foregroundStyle(.white)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .padding(.top, AppTheme.Spacing.small)
        }
    }

    private func statsPill(mealCount: Int, avg: Double) -> some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Text(Strings.Insight.Preparing.todaySoFarLabel)
                .font(FontTheme.caption)
                .foregroundStyle(.secondary)
            Text(String(
                format: Strings.Insight.Preparing.statsSummaryFmt,
                mealCount,
                Int(avg * 100)
            ))
            .font(FontTheme.caption.weight(.medium))
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.small)
    }
}

#Preview("Generating") {
    InsightPreparingSheet(contract: InsightPreparingSheetContract(
        weekdayName: "Wednesday",
        isGenerating: true,
        mealCount: 3,
        averageScore: 0.86,
        onRefresh: {},
        onDismiss: {}
    ))
}

#Preview("Needs refresh") {
    InsightPreparingSheet(contract: InsightPreparingSheetContract(
        weekdayName: "Wednesday",
        isGenerating: false,
        mealCount: 0,
        averageScore: nil,
        onRefresh: {},
        onDismiss: {}
    ))
}
