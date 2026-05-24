import SwiftUI

/// A popup sheet showing a specific day's eating history.
/// Presented as a bottom sheet from the yearly heatmap.
struct DayMealPopupView: View {
    let snapshot: DailySmileySnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                self.headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                if self.snapshot.meals.isEmpty {
                    self.emptyState
                } else {
                    Divider()
                    self.mealsSection
                }

                if let reflection = self.snapshot.reflection {
                    self.reflectionSection(reflection)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }

                Color.clear.frame(height: 20)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(self.formattedDate)
                    .font(FontTheme.textEntry(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Text("\(self.snapshot.mealCount) meal\(self.snapshot.mealCount == 1 ? "" : "s")")
                        .font(FontTheme.caption)
                        .foregroundColor(.secondary)

                    if self.snapshot.mealCount > 0 {
                        Circle()
                            .fill(Color.secondary.opacity(0.35))
                            .frame(width: 3, height: 3)

                        self.avgScorePill
                    }
                }
            }

            Spacer()

            SmileyView(state: self.snapshot.displayState)
                .frame(width: 44, height: 44)
                .padding(.trailing, 4)
        }
    }

    private var avgScorePill: some View {
        let color = self.scoreColor(self.snapshot.averageHealthScore)
        let pct = Int(self.snapshot.averageHealthScore * 100)
        return Text("avg \(pct)%")
            .font(FontTheme.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
    }

    // MARK: - Meals

    private var mealsSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(self.snapshot.meals.enumerated()), id: \.element.id) { index, meal in
                self.mealRow(meal)
                if index < self.snapshot.meals.count - 1 {
                    Divider()
                        .padding(.leading, 20)
                }
            }
        }
    }

    private func mealRow(_ meal: Meal) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                MealTypeTag(mealType: meal.mealType)
                Text(self.formattedTime(meal.timestamp))
                    .font(FontTheme.caption)
                    .foregroundColor(Color.secondary.opacity(0.6))
                Spacer()
                if meal.isAIAnalyzed {
                    self.scorePill(for: meal)
                }
            }

            Text(self.mealItemsText(meal.items))
                .font(FontTheme.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let insight = meal.aiInsight, !insight.isEmpty {
                Text(insight)
                    .font(FontTheme.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func scorePill(for meal: Meal) -> some View {
        let color = meal.mealType.displayColor
        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(Int(meal.healthScore * 100))%")
                .font(FontTheme.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.10)))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife")
                .font(.title2)
                .foregroundColor(Color.secondary.opacity(0.4))
            Text("No meals logged")
                .font(FontTheme.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
    }

    // MARK: - Reflection

    private func reflectionSection(_ reflection: DailyReflection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reflection")
                .font(FontTheme.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)

            HStack(spacing: 8) {
                if let feeling = reflection.feeling {
                    self.reflectionPill(
                        emoji: feeling.emoji,
                        label: feeling.displayName,
                        color: .blue
                    )
                }
                if let sleep = reflection.sleepQuality {
                    self.reflectionPill(
                        emoji: sleep.emoji,
                        label: "Sleep · \(sleep.displayName)",
                        color: .indigo
                    )
                }
            }

            if let note = reflection.note, !note.isEmpty {
                Text(note)
                    .font(FontTheme.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private func reflectionPill(emoji: String, label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Text(emoji)
                .font(.subheadline)
            Text(label)
                .font(FontTheme.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(color.opacity(0.10)))
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: self.snapshot.date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    /// Shows all items when ≤ 3; otherwise first 3 followed by "+ N more".
    /// Avoids mid-word truncation caused by lineLimit on a raw joined string.
    private func mealItemsText(_ items: [String]) -> String {
        let limit = 3
        guard items.count > limit else { return items.joined(separator: ", ") }
        return items.prefix(limit).joined(separator: ", ") + " + \(items.count - limit) more"
    }

    /// 4-band score color aligned with MealScoreBadge and ScoreCategory.colorName:
    /// green  >  0.75 (colorBandHigh) — excellent
    /// teal   >= 0.55 (colorBandMid)  — good
    /// orange >= 0.35 (unhealthy)     — moderate  (40% is now orange, not blue)
    /// red     < 0.35                 — poor
    private func scoreColor(_ score: Double) -> Color {
        if score > ScoringThresholds.colorBandHigh { return .green }
        if score >= ScoringThresholds.colorBandMid { return .teal }
        if score >= ScoringThresholds.unhealthy { return .orange }
        return .red
    }
}

#Preview {
    DayMealPopupView(
        snapshot: DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: SmileyState(scale: 1.0, mood: .serene),
            meals: [
                Meal(
                    id: UUID(),
                    timestamp: Date(),
                    mealType: .breakfast,
                    items: ["Oatmeal", "Banana", "Almond milk"],
                    healthScore: 0.88,
                    isAIAnalyzed: true,
                    aiInsight: "Great start — whole grains and fruit provide sustained energy."
                ),
                Meal(
                    id: UUID(),
                    timestamp: Date(),
                    mealType: .lunch,
                    items: ["150gm rice", "100gm Chicken Yakhani"],
                    healthScore: 0.72,
                    isAIAnalyzed: true,
                    aiInsight: nil
                ),
                Meal(
                    id: UUID(),
                    timestamp: Date(),
                    mealType: .drinks,
                    items: ["1 cup Earl Grey Tea without milk & sugar"],
                    healthScore: 0.95,
                    isAIAnalyzed: true,
                    aiInsight: nil
                )
            ],
            mealCount: 3,
            averageHealthScore: 0.85,
            reflection: DailyReflection(
                feeling: .calm,
                sleepQuality: .good,
                timestamp: Date()
            )
        )
    )
}
