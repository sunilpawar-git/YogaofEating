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
                    self.whySection
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

    // MARK: - Sections

    private var whySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.WellbeingBreakdown.whyHeading)
                .font(FontTheme.sectionHeader)
            Text(self.contract.causalNarrative)
                .font(FontTheme.body)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var dimensionsSection: some View {
        VStack(spacing: 14) {
            ForEach(WellbeingDimension.allCases, id: \.self) { dimension in
                WellbeingDimensionBar(
                    dimension: dimension,
                    value: dimension.value(in: self.contract.dimensions),
                    isDominant: dimension == self.contract.dominantDimension
                )
            }
        }
    }
}

// MARK: - Dimension Bar

private struct WellbeingDimensionBar: View {
    let dimension: WellbeingDimension
    let value: Double
    let isDominant: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(self.dimension.displayName)
                    .font(FontTheme.caption)
                    .fontWeight(self.isDominant ? .semibold : .regular)
                if self.isDominant {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.Dimension.color(for: self.dimension))
                }
                Spacer()
                Text("\(Int(self.value * 100))%")
                    .font(FontTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(AppTheme.cardBackground)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(AppTheme.Dimension.color(for: self.dimension))
                        .frame(width: geo.size.width * max(0, min(1, self.value)), height: 8)
                }
            }
            .frame(height: 8)
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
            causalNarrative: "Your food choices are driving today's state.",
            weakDimensions: []
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
            causalNarrative: "Your mood and feelings are shaping today.",
            weakDimensions: [.emotionalTone, .cognitiveClarity]
        )
    )
}
