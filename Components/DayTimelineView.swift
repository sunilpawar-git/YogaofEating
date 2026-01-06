import SwiftUI

/// A reusable view that displays a day's meal timeline.
/// Used for both today (editable) and historical days (read-only).
struct DayTimelineView: View {
    /// The meals to display in the timeline
    let meals: [Meal]

    /// The fasting periods between meals (for connectors)
    let fastingPeriods: [FastingPeriod]

    /// Whether this view is for today (editable) or a historical day (read-only)
    let isToday: Bool

    /// The smiley state to display (for today's add button)
    let smileyState: SmileyState

    /// Optional snapshot for historical days (contains reflection, etc.)
    let snapshot: DailySmileySnapshot?

    /// Callback when user taps the smiley (only for today)
    /// This should trigger context-aware reflection prompts before meal creation
    var onSmileyTap: (() -> Void)?

    /// Callback when user taps to edit sleep quality badge (only for today)
    var onEditSleep: (() -> Void)?

    /// Callback when user taps to edit overall feeling badge (only for today)
    var onEditFeeling: (() -> Void)?

    /// Today's logged sleep quality (for displaying badge)
    var todaysSleepQuality: SleepQuality?

    /// Today's logged overall feeling (for displaying badge)
    var todaysFeeling: ReflectionFeeling?

    /// Callback when a meal is updated
    var onUpdateMeal: ((UUID, MealType, [String]) -> Void)?

    /// Callback when a meal's timestamp is updated
    var onUpdateTimestamp: ((UUID, Date) -> Void)?

    /// Callback when a meal is deleted
    var onDeleteMeal: ((UUID) -> Void)?

    // MARK: - State

    @State private var breathingMeals: Set<UUID> = []

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Sleep badge at TOP of timeline (for today only)
            if self.isToday, let sleepQuality = self.todaysSleepQuality {
                self.sleepBadge(sleepQuality)
                    .padding(.bottom, 16)
            }

            let sortedMeals = self.meals.sorted { $0.timestamp < $1.timestamp }

            ForEach(Array(sortedMeals.enumerated()), id: \.element.id) { index, meal in
                self.mealBlockView(for: meal)
                    .id(meal.id)

                // Show fasting connector after each meal (except the last one)
                if index < sortedMeals.count - 1,
                   let period = self.fastingPeriods.first(where: { $0.startMealId == meal.id })
                {
                    self.fastingConnector(for: period)
                } else if index < sortedMeals.count - 1 {
                    // Fallback spacing if no period found
                    Spacer().frame(height: 30)
                }
            }

            // Feeling badge above smiley (for today only, when logged)
            if self.isToday, let feeling = self.todaysFeeling {
                self.feelingBadge(feeling)
                    .padding(.top, 16)
            }

            // Show appropriate bottom content based on whether it's today or historical
            if self.isToday {
                self.smileyAddButton
                    .padding(.top, self.todaysFeeling != nil ? 12 : (sortedMeals.isEmpty ? 20 : 30))
            } else {
                self.historicalDaySummary
                    .padding(.top, sortedMeals.isEmpty ? 20 : 30)
            }
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .center) { self.timelineLine }
    }

    // MARK: - Meal Block

    @ViewBuilder
    private func mealBlockView(for meal: Meal) -> some View {
        if self.isToday {
            JournalBlockView(
                meal: meal,
                isBreathing: self.breathingMeals.contains(meal.id),
                onUpdate: { mealType, newItems in
                    self.onUpdateMeal?(meal.id, mealType, newItems)
                },
                onTimestampUpdate: { newTimestamp in
                    self.onUpdateTimestamp?(meal.id, newTimestamp)
                },
                onDelete: {
                    withAnimation(.spring()) {
                        self.onDeleteMeal?(meal.id)
                    }
                }
            )
        } else {
            // Read-only view for historical days
            ReadOnlyMealCardView(meal: meal)
        }
    }

    // MARK: - Fasting Connector

    private func fastingConnector(for period: FastingPeriod) -> some View {
        let spacing = FastingLogicService.calculateSpacing(for: period)
        let showBadge = FastingLogicService.shouldShowBadge(for: period)

        return ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: period.isSignificant
                            ? [.green.opacity(0.2), .green.opacity(0.1)]
                            : [.primary.opacity(0.08), .primary.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: period.isSignificant ? 3 : 2, height: spacing)
                .shadow(
                    color: period.isSignificant ? .green.opacity(0.3 * period.glowIntensity) : .clear,
                    radius: 4,
                    x: 0,
                    y: 0
                )

            if showBadge {
                FastingBadgeView(fastingPeriod: period)
            }
        }
        .frame(height: spacing)
    }

    // MARK: - Timeline Line

    private var timelineLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.primary.opacity(0.1), .primary.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2)
            .padding(.top, 20)
    }

    // MARK: - Reflection Badges (Today Only)

    private func sleepBadge(_ quality: SleepQuality) -> some View {
        ReflectionBadgeView(
            type: .sleep(quality),
            isTappable: true,
            onTap: {
                self.onEditSleep?()
            }
        )
    }

    private func feelingBadge(_ feeling: ReflectionFeeling) -> some View {
        ReflectionBadgeView(
            type: .feeling(feeling),
            isTappable: true,
            onTap: {
                self.onEditFeeling?()
            }
        )
    }

    // MARK: - Smiley Add Button (Today Only)

    private var smileyAddButton: some View {
        Button(action: {
            self.onSmileyTap?()
            SensoryService.shared.playNudge(style: .medium)
        }) {
            VStack(spacing: 16) {
                SmileyView(state: self.smileyState)
                    .frame(width: 120, height: 120)

                Text("TAP TO LOG")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .kerning(2)
                    .fixedSize()

                Text(QuoteService.getDailyQuote().text)
                    .font(.system(size: 11, design: .serif))
                    .italic()
                    .foregroundColor(.secondary.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Daily mindful eating quote")
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("add-meal-button")
        .accessibilityLabel("Add Meal")
    }

    // MARK: - Historical Day Summary

    private var historicalDaySummary: some View {
        VStack(spacing: 16) {
            // Smiley showing that day's state
            if let snapshot = self.snapshot {
                SmileyView(state: snapshot.displayState)
                    .frame(width: 80, height: 80)
            } else {
                SmileyView(state: .neutral)
                    .frame(width: 80, height: 80)
            }

            // Summary text
            if self.meals.isEmpty {
                Text("No meals logged")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 4) {
                    Text("\(self.meals.count) meal\(self.meals.count == 1 ? "" : "s") logged")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let avgScore = self.snapshot?.averageHealthScore {
                        Text("Avg. Health Score: \(Int(avgScore * 100))%")
                            .font(.caption)
                            .foregroundColor(self.scoreColor(avgScore))
                    }
                }
            }

            // Show reflection if available
            if let reflection = self.snapshot?.reflection {
                self.reflectionSummary(reflection)
            }
        }
        .padding(.vertical, 20)
    }

    private func reflectionSummary(_ reflection: DailyReflection) -> some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.horizontal, 40)

            HStack(spacing: 12) {
                if let feeling = reflection.feeling {
                    Text(feeling.emoji)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Felt \(feeling.displayName.lowercased())")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if let sleep = reflection.sleepQuality {
                            Text("Sleep: \(sleep.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else if let sleep = reflection.sleepQuality {
                    Text(sleep.emoji)
                        .font(.title2)

                    Text("Sleep: \(sleep.displayName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            if let note = reflection.note, !note.isEmpty {
                Text("\"\(note)\"")
                    .font(.caption)
                    .italic()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.8 { return .green }
        if score >= 0.5 { return .blue }
        return .orange
    }
}

// MARK: - Read-Only Meal Card

/// A simplified, non-editable meal card for historical views.
struct ReadOnlyMealCardView: View {
    let meal: Meal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                MealTypeTag(mealType: self.meal.mealType, isSelected: true)

                Spacer()

                Text(self.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !self.meal.items.isEmpty {
                Text(self.meal.items.joined(separator: ", "))
                    .font(.body)
                    .foregroundColor(.primary)
            } else {
                Text("No items logged")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }

            HStack {
                Text("\(self.meal.items.count) item\(self.meal.items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Health score indicator
                Circle()
                    .fill(self.scoreColor)
                    .frame(width: 8, height: 8)

                Text("\(Int(self.meal.healthScore * 100))%")
                    .font(.caption)
                    .foregroundColor(self.scoreColor)
            }
        }
        .padding()
        .background(
            ZStack {
                // Opaque base layer to completely cover the timeline line - pleasant light green
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                // Tinted layer on top
                RoundedRectangle(cornerRadius: 16)
                    .fill(self.cardBackground)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(self.borderColor, lineWidth: 2)
        )
        .padding(.horizontal, 20)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self.meal.timestamp)
    }

    private var scoreColor: Color {
        if self.meal.healthScore >= 0.8 { return .green }
        if self.meal.healthScore >= 0.5 { return .blue }
        return .orange
    }

    private var cardBackground: Color {
        if self.meal.healthScore >= 0.7 {
            Color.green.opacity(0.08)
        } else if self.meal.healthScore >= 0.4 {
            Color.blue.opacity(0.05)
        } else {
            Color.orange.opacity(0.08)
        }
    }

    private var borderColor: Color {
        if self.meal.healthScore >= 0.7 {
            Color.green.opacity(0.3)
        } else if self.meal.healthScore >= 0.4 {
            Color.blue.opacity(0.2)
        } else {
            Color.orange.opacity(0.3)
        }
    }
}

// MARK: - Preview

#Preview("Today Timeline") {
    ScrollView {
        DayTimelineView(
            meals: [
                Meal(mealType: .breakfast, items: ["Oatmeal", "Berries"], healthScore: 0.9),
                Meal(mealType: .lunch, items: ["Salad", "Chicken"], healthScore: 0.8)
            ],
            fastingPeriods: [],
            isToday: true,
            smileyState: .neutral,
            snapshot: nil,
            onSmileyTap: { print("Smiley tapped") },
            todaysSleepQuality: .good,
            todaysFeeling: .calm
        )
    }
}

#Preview("Historical Day") {
    ScrollView {
        DayTimelineView(
            meals: [
                Meal(mealType: .breakfast, items: ["Coffee"], healthScore: 0.5),
                Meal(mealType: .dinner, items: ["Pizza", "Soda"], healthScore: 0.3)
            ],
            fastingPeriods: [],
            isToday: false,
            smileyState: .neutral,
            snapshot: DailySmileySnapshot(
                id: UUID(),
                date: Date(),
                smileyState: SmileyState(scale: 1.2, mood: .overwhelmed),
                meals: [],
                mealCount: 2,
                averageHealthScore: 0.4,
                reflection: DailyReflection(feeling: .heavy, sleepQuality: .poor, note: "Overate")
            )
        )
    }
}
