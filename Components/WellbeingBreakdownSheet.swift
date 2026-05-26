import SwiftUI

/// Sheet showing the four-dimension wellbeing breakdown and the causal narrative
/// explaining why the smiley changed.
///
/// Follows the data-contract pattern — accepts only `WellbeingBreakdownSheetContract`.
/// No direct reference to `MainViewModel`.
struct WellbeingBreakdownSheet: View {
    let contract: WellbeingBreakdownSheetContract
    var onDismiss: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    self.stateHeroSection
                    self.progressSection
                    Divider()
                    self.whySection
                    self.weakDimsSection
                    Divider()
                    self.dimensionsSection
                }
                .padding()
            }
            .navigationTitle(Strings.WellbeingBreakdown.sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.WellbeingBreakdown.done) {
                        self.onDismiss?()
                    }
                }
            }
        }
    }

    // MARK: - State Hero

    private var stateHeroSection: some View {
        HStack(spacing: 14) {
            Text(self.contract.currentMood.emoji)
                .font(.system(size: 44))
                .accessibilityLabel(
                    String(
                        format: Strings.WellbeingBreakdown.heroEmojiAccessibilityFmt,
                        self.contract.currentMood.displayName
                    )
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(self.contract.currentMood.displayName)
                    .font(FontTheme.sectionHeader)
                Text(self.contract.currentMood.tagline)
                    .font(FontTheme.body)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - Progress Pill

    @ViewBuilder
    private var progressSection: some View {
        if let text = WellbeingProgressCalculator.progressText(
            mood: self.contract.currentMood,
            overall: self.contract.overallScore
        ) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.circle")
                    .foregroundStyle(AppTheme.Dimension.color(for: self.contract.dominantDimension))
                Text(text)
                    .font(FontTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .accessibilityLabel(text)
            .pillStyle()
        }
    }

    // MARK: - Why Section

    private var whySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.WellbeingBreakdown.whyHeading)
                .font(FontTheme.sectionHeader)
            Text(self.contract.causalNarrative)
                .font(FontTheme.body)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    // MARK: - Weak Dimensions

    @ViewBuilder
    private var weakDimsSection: some View {
        if !self.contract.weakDimensions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.WellbeingBreakdown.worthNurturing)
                    .font(FontTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
                HStack(spacing: 8) {
                    ForEach(self.contract.weakDimensions, id: \.self) { dim in
                        Text(dim.displayName)
                            .font(FontTheme.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.Dimension.color(for: dim).opacity(0.15))
                            .foregroundStyle(AppTheme.Dimension.color(for: dim))
                            .clipShape(RoundedRectangle(
                                cornerRadius: AppTheme.CornerRadius.small,
                                style: .continuous
                            ))
                            .accessibilityLabel(
                                String(
                                    format: Strings.WellbeingBreakdown.weakDimChipAccessibilityFmt,
                                    dim.displayName
                                )
                            )
                    }
                }
            }
        }
    }

    // MARK: - Dimensions

    private var dimensionsSection: some View {
        VStack(spacing: 14) {
            ForEach(WellbeingDimension.allCases, id: \.self) { dimension in
                WellbeingDimensionBar(
                    dimension: dimension,
                    value: dimension.value(in: self.contract.dimensions),
                    isDominant: dimension == self.contract.dominantDimension,
                    mealCount: self.contract.mealCount
                )
            }
        }
    }
}

// MARK: - Previews

#Preview("Strong day") {
    WellbeingBreakdownSheet(
        contract: WellbeingBreakdownSheetContract(
            dimensions: WellbeingDimensions(
                physicalLoad: 0.8, emotionalTone: 0.72, cognitiveClarity: 0.65, behavioralMomentum: 0.78
            ),
            dominantDimension: .physicalLoad,
            causalNarrative: "What you're eating is lifting you up today.",
            weakDimensions: [],
            mealCount: 3,
            currentMood: .serene,
            overallScore: 0.74
        )
    )
}

#Preview("Needs attention") {
    WellbeingBreakdownSheet(
        contract: WellbeingBreakdownSheetContract(
            dimensions: WellbeingDimensions(
                physicalLoad: 0.55, emotionalTone: 0.3, cognitiveClarity: 0.4, behavioralMomentum: 0.6
            ),
            dominantDimension: .emotionalTone,
            causalNarrative: "Your feelings are at the heart of today — give yourself some grace.",
            weakDimensions: [.emotionalTone, .cognitiveClarity],
            mealCount: 1,
            currentMood: .thoughtful,
            overallScore: 0.46
        )
    )
}
