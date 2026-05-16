import SwiftUI

// MARK: - CalorieDetailSheet

/// A bottom sheet showing a full breakdown of daily calorie consumption vs TDEE.
///
/// Layout (top to bottom):
///   1. Progress — Consumed + Remaining above bar, bar, Total Goal below
///   2. Goal breakdown — Base Goal + Exercise = Total Goal (only when applicable)
///   3. By meal — per-meal calorie breakdown
///   4. Macros — Protein / Carbs / Fat totals (only when any meal has complete macro data)
///
/// Accepts only `CalorieDetailData` — never references `MainViewModel` directly.
/// Follows the Principle of Least Privilege: receives only what it needs.
struct CalorieDetailSheet: View {
    let data: CalorieDetailData

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                self.progressSection
                self.goalSection
                if !self.data.mealBreakdown.isEmpty {
                    self.mealBreakdownSection
                }
                if let macros = self.data.macroTotals {
                    self.macroSection(macros)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Strings.CaloriePill.detailHeading)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) { self.dismiss() }
                        .font(FontTheme.body)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Progress Section

    /// Row 1: Consumed (left) + Remaining (right)
    /// Row 2: Progress bar
    /// Row 3: Total Goal (right-aligned, secondary) — only when TDEE is known
    private var progressSection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                self.consumedRemainingRow
                if self.data.tdee != nil {
                    self.progressBar
                    self.totalGoalRow
                }
            }
            .padding(.vertical, AppTheme.Spacing.xSmall)
        }
    }

    /// "Consumed  560 Cal"  ·  "Remaining  1,514 Cal" on a single line.
    private var consumedRemainingRow: some View {
        HStack {
            HStack(spacing: AppTheme.Spacing.xSmall) {
                Text(Strings.CaloriePill.rowConsumed)
                    .font(FontTheme.body)
                    .foregroundColor(.primary)
                Text(Strings.CaloriePill.consumedOnly(CaloriePillData.formatted(self.data.consumed)))
                    .font(FontTheme.body)
                    .foregroundColor(.primary)
            }
            Spacer()
            if let remaining = self.data.remaining {
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    Text(remaining >= 0 ? Strings.CaloriePill.rowRemaining : Strings.CaloriePill.rowOver)
                        .font(FontTheme.body)
                        .foregroundColor(remaining >= 0 ? AppTheme.CaloriePill.colorRemaining : AppTheme.CaloriePill
                            .fillOver)
                    Text(Strings.CaloriePill.consumedOnly(CaloriePillData.formatted(abs(remaining))))
                        .font(FontTheme.body)
                        .fontWeight(remaining >= 0 ? .regular : .semibold)
                        .foregroundColor(remaining >= 0 ? AppTheme.CaloriePill.colorRemaining : AppTheme.CaloriePill
                            .fillOver)
                }
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.CaloriePill.pillBackground)
                Capsule()
                    .fill(self.data.progressFillColor)
                    .frame(width: max(0, self.data.progressFraction * geo.size.width))
                    .animation(AppTheme.Animation.slow, value: self.data.progressFraction)
            }
        }
        .frame(height: 8)
        .accessibilityLabel(Strings.CaloriePill.progressBarAccessibilityLabel)
        .accessibilityValue(
            self.data.formattedTDEE.map {
                Strings.CaloriePill.accessibilityLabel(
                    consumed: CaloriePillData.formatted(self.data.consumed),
                    tdee: $0
                )
            } ?? ""
        )
    }

    /// "Total Goal  2,074 Cal" — right-aligned anchor below the bar.
    @ViewBuilder
    private var totalGoalRow: some View {
        if let tdee = self.data.tdee {
            HStack {
                Spacer()
                Text(Strings.CaloriePill.rowGoalTotal)
                    .font(FontTheme.body)
                    .foregroundColor(.secondary)
                Text(Strings.CaloriePill.consumedOnly(CaloriePillData.formatted(tdee)))
                    .font(FontTheme.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Goal Section

    /// Shows how the TDEE goal was calculated.
    /// Expands to "Base Goal + Exercise = Total Goal" when exercise data is present;
    /// collapses to a single "Goal" row otherwise — prevents empty sections.
    @ViewBuilder
    private var goalSection: some View {
        if let tdee = self.data.tdee {
            if self.data.hasGoalBreakdown, let base = self.data.profileBaseTdee {
                let activeInt = self.data.activeCalories.map { Int($0.rounded()) } ?? 0
                Section(Strings.CaloriePill.sectionGoalBreakdown) {
                    self.detailRow(
                        label: Strings.CaloriePill.rowGoalBase,
                        value: Strings.CaloriePill.consumedOnly(CaloriePillData.formatted(base)),
                        color: .secondary
                    )
                    self.detailRow(
                        label: Strings.CaloriePill.rowGoalExercise,
                        value: Strings.CaloriePill.exerciseCalories(CaloriePillData.formatted(activeInt)),
                        color: .secondary
                    )
                    self.detailRow(
                        label: Strings.CaloriePill.rowGoalTotal,
                        value: Strings.CaloriePill.consumedOnly(CaloriePillData.formatted(tdee)),
                        color: .primary
                    )
                }
            } else {
                Section(Strings.CaloriePill.sectionGoalBreakdown) {
                    self.detailRow(
                        label: Strings.CaloriePill.rowGoal,
                        value: Strings.CaloriePill.consumedOnly(CaloriePillData.formatted(tdee)),
                        color: .secondary
                    )
                }
            }
        }
    }

    // MARK: - Meal Breakdown Section

    private var mealBreakdownSection: some View {
        Section(Strings.CaloriePill.sectionByMeal) {
            ForEach(self.data.mealBreakdown, id: \.label) { entry in
                HStack {
                    Text(entry.label)
                        .font(FontTheme.body)
                    Spacer()
                    Text(Strings.CaloriePill.estimatedCalories(CaloriePillData.formatted(entry.calories)))
                        .font(FontTheme.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Macros Section

    private func macroSection(_ macros: MacroTotals) -> some View {
        Section(Strings.Macros.sectionHeader) {
            self.macroRow(label: Strings.Macros.protein, grams: macros.protein, partial: macros.isPartial)
            self.macroRow(label: Strings.Macros.carbs, grams: macros.carbs, partial: macros.isPartial)
            self.macroRow(label: Strings.Macros.fat, grams: macros.fat, partial: macros.isPartial)
        }
    }

    private func macroRow(label: String, grams: Int, partial: Bool) -> some View {
        HStack {
            Text(label).font(FontTheme.body)
            Spacer()
            Text(Strings.Macros.gramsLabel(grams, partial: partial))
                .font(FontTheme.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Macros.accessibilityLabel(macro: label, grams: grams, partial: partial))
    }

    // MARK: - Helpers

    private func detailRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(FontTheme.body)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(FontTheme.body)
                .foregroundColor(color)
        }
    }
}

// MARK: - CalorieDetailData helpers used by view

private extension CalorieDetailData {
    var formattedTDEE: String? {
        self.tdee.map { CaloriePillData.formatted($0) }
    }
}

// MARK: - Preview

#Preview("Full breakdown — morning (27% consumed)") {
    CalorieDetailSheet(
        data: CalorieDetailData(
            consumed: 560,
            tdee: 2074,
            profileBaseTdee: 1910,
            meals: {
                var drinks = Meal(mealType: .drinks, items: ["Tea"])
                drinks.estimatedCalories = 10
                var breakfast = Meal(mealType: .breakfast, items: ["Oatmeal", "Banana"])
                breakfast.estimatedCalories = 550
                return [drinks, breakfast]
            }(),
            basalCalories: 777,
            activeCalories: 164
        )
    )
}

#Preview("Approaching goal (80% consumed)") {
    CalorieDetailSheet(
        data: CalorieDetailData(
            consumed: 1650,
            tdee: 2074,
            profileBaseTdee: 1910,
            meals: {
                var lunch = Meal(mealType: .lunch, items: ["Brown rice", "Chicken"])
                lunch.estimatedCalories = 620
                var breakfast = Meal(mealType: .breakfast, items: ["Oatmeal"])
                breakfast.estimatedCalories = 380
                var snack = Meal(mealType: .snacks, items: ["Yogurt"])
                snack.estimatedCalories = 150
                var dinner = Meal(mealType: .dinner, items: ["Dal", "Roti"])
                dinner.estimatedCalories = 500
                return [breakfast, lunch, snack, dinner]
            }(),
            basalCalories: 1300,
            activeCalories: 164
        )
    )
}

#Preview("Over goal") {
    CalorieDetailSheet(
        data: CalorieDetailData(
            consumed: 2300,
            tdee: 2074,
            profileBaseTdee: 1910,
            meals: {
                var dinner = Meal(mealType: .dinner, items: ["Large meal"])
                dinner.estimatedCalories = 2300
                return [dinner]
            }(),
            activeCalories: 164
        )
    )
}

#Preview("No profile — consumed only") {
    CalorieDetailSheet(
        data: CalorieDetailData(
            consumed: 850,
            tdee: nil,
            meals: {
                var meal = Meal(mealType: .lunch, items: ["Salad"])
                meal.estimatedCalories = 850
                return [meal]
            }()
        )
    )
}
