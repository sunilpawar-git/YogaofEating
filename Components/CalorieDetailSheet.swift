import SwiftUI

// MARK: - CalorieDetailSheet

/// A bottom sheet showing a full breakdown of daily calorie consumption vs TDEE,
/// including a per-meal breakdown and optional Apple Watch activity data.
///
/// Accepts only `CalorieDetailData` — never references `MainViewModel` directly.
/// Follows the Principle of Least Privilege: receives only what it needs.
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showDetail) {
///     CalorieDetailSheet(data: viewModel.calorieDetailData)
/// }
/// ```
struct CalorieDetailSheet: View {
    let data: CalorieDetailData

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                self.summarySection
                if let basal = self.data.basalCalories, let active = self.data.activeCalories {
                    self.activitySection(basal: basal, active: active)
                }
                if !self.data.mealBreakdown.isEmpty {
                    self.mealBreakdownSection
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

    // MARK: - Summary Section

    private var summarySection: some View {
        Section {
            self.summaryRow(
                label: Strings.CaloriePill.rowConsumed,
                value: Strings.CaloriePill.consumedOnly(CaloriePillData.formatted(self.data.consumed)),
                color: .primary
            )

            if let tdee = self.data.tdee {
                self.summaryRow(
                    label: Strings.CaloriePill.rowGoal,
                    value: Strings.CaloriePill.consumedOnly(CaloriePillData.formatted(tdee)),
                    color: .secondary
                )

                if let remaining = self.data.remaining {
                    let formattedRemaining = CaloriePillData.formatted(abs(remaining))
                    self.summaryRow(
                        label: Strings.CaloriePill.rowRemaining,
                        value: Strings.CaloriePill.consumedOnly(formattedRemaining),
                        color: remaining >= 0 ? AppTheme.CaloriePill.colorRemaining : AppTheme.CaloriePill.fillOver
                    )
                }
            }
        }
    }

    // MARK: - Activity Section

    private func activitySection(basal: Double, active: Double) -> some View {
        Section(Strings.CaloriePill.sectionActivity) {
            self.summaryRow(
                label: Strings.CaloriePill.rowBasal,
                value: Strings.CaloriePill.consumedOnly(CaloriePillData.formatted(Int(basal.rounded()))),
                color: .secondary
            )
            self.summaryRow(
                label: Strings.CaloriePill.rowActive,
                value: Strings.CaloriePill.consumedOnly(CaloriePillData.formatted(Int(active.rounded()))),
                color: .secondary
            )
            self.summaryRow(
                label: Strings.CaloriePill.rowTotalTDEE,
                value: Strings.CaloriePill.consumedOnly(CaloriePillData.formatted(Int((basal + active).rounded()))),
                color: .primary
            )
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

    // MARK: - Helpers

    private func summaryRow(label: String, value: String, color: Color) -> some View {
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

// MARK: - Preview

#Preview {
    CalorieDetailSheet(
        data: CalorieDetailData(
            consumed: 1150,
            tdee: 2200,
            meals: {
                var lunch = Meal(mealType: .lunch, items: ["Brown rice", "Grilled chicken", "Broccoli"])
                lunch.estimatedCalories = 620
                var breakfast = Meal(mealType: .breakfast, items: ["Oatmeal", "Banana"])
                breakfast.estimatedCalories = 380
                var snack = Meal(mealType: .snacks, items: ["Greek yogurt"])
                snack.estimatedCalories = 150
                return [breakfast, lunch, snack]
            }(),
            basalCalories: 1450,
            activeCalories: 750
        )
    )
}
