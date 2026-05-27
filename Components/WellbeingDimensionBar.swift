import SwiftUI

/// Horizontal progress bar row for a single wellbeing dimension.
/// Shared between `WellbeingBreakdownSheet` and `BriefingDetailView`.
struct WellbeingDimensionBar: View {
    let dimension: WellbeingDimension
    let value: Double
    let isDominant: Bool
    let mealCount: Int
    var weeklyAverage: Double?
    var hasExerciseBonus: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(self.dimension.displayName)
                            .font(FontTheme.caption)
                            .fontWeight(self.isDominant ? .semibold : .regular)
                        if self.isDominant {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.Dimension.color(for: self.dimension))
                        }
                        if let avg = self.weeklyAverage {
                            Text(String(format: Strings.WellbeingBreakdown.weeklyAvgFmt, Int(avg * 100)))
                                .font(FontTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }
                    Text(self.dimension.subtitle(mealCount: self.mealCount, hasExerciseBonus: self.hasExerciseBonus))
                        .font(FontTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }
                Spacer()
                Text("\(Int(self.value * 100))%")
                    .font(FontTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            .accessibilityLabel(
                String(
                    format: Strings.WellbeingBreakdown.dimensionBarAccessibilityFmt,
                    self.dimension.displayName,
                    Int(self.value * 100)
                )
            )
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

#Preview("Physical — dominant") {
    VStack(spacing: 14) {
        WellbeingDimensionBar(dimension: .physicalLoad, value: 0.85, isDominant: true, mealCount: 3)
        WellbeingDimensionBar(dimension: .emotionalTone, value: 0.5, isDominant: false, mealCount: 3)
        WellbeingDimensionBar(dimension: .cognitiveClarity, value: 0.31, isDominant: false, mealCount: 3)
        WellbeingDimensionBar(dimension: .behavioralMomentum, value: 0.1, isDominant: false, mealCount: 3)
    }
    .padding()
}

#Preview("Emotional — dominant, 1 meal") {
    VStack(spacing: 14) {
        WellbeingDimensionBar(dimension: .physicalLoad, value: 0.3, isDominant: false, mealCount: 1)
        WellbeingDimensionBar(dimension: .emotionalTone, value: 0.72, isDominant: true, mealCount: 1)
        WellbeingDimensionBar(dimension: .cognitiveClarity, value: 0.55, isDominant: false, mealCount: 1)
        WellbeingDimensionBar(dimension: .behavioralMomentum, value: 0.4, isDominant: false, mealCount: 1)
    }
    .padding()
}
