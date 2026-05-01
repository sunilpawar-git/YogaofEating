import SwiftUI

// MARK: - Day Timeline View

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

    /// Callback when user long-presses the smiley (only for today)
    /// This should show the insight bottom sheet if available
    var onSmileyLongPress: (() -> Void)?

    /// Whether an insight is available (for showing red dot indicator)
    var hasInsightAvailable: Bool = false

    /// Data-contract tuple for the morning briefing card (nil hides it).
    var briefingCardData: (headline: String, topCorrelation: String?, nudge: String, isViewed: Bool)?

    /// Callback when user taps the briefing card
    var onBriefingTap: (() -> Void)?

    /// Grouped meal update actions (reduces callback proliferation)
    var mealActions: MealUpdateActions = .empty

    /// Recent meals from past 3 days for quick-add feature (only for today)
    var recentMeals: [Meal] = []

    /// Pre-computed average health score for the day summary line (today only, >= 2 meals).
    /// Provided by the ViewModel to avoid duplicating averaging logic inside the view.
    /// Nil means the summary line is not shown.
    var averageHealthScore: Double?

    // MARK: - State

    @State private var breathingMeals: Set<UUID> = []
    @State private var showInsightCoachmark: Bool = false
    @State private var isSmileyPulsing: Bool = false
    @AppStorage(StorageKeys.insightCoachmarkSeen) private var insightCoachmarkSeen: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if self.isToday, let data = self.briefingCardData {
                MorningBriefingCard(
                    headline: data.headline,
                    topCorrelation: data.topCorrelation,
                    nudge: data.nudge,
                    isViewed: data.isViewed,
                    onTap: self.onBriefingTap
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            let sortedMeals = self.meals.sorted { $0.timestamp < $1.timestamp }

            ForEach(Array(sortedMeals.enumerated()), id: \.element.id) { index, meal in
                self.mealBlockView(for: meal)
                    .id(meal.id)

                if index < sortedMeals.count - 1,
                   let period = self.fastingPeriods.first(where: { $0.startMealId == meal.id })
                {
                    self.fastingConnector(for: period)
                } else if index < sortedMeals.count - 1 {
                    Spacer().frame(height: 30)
                }
            }

            if self.isToday {
                self.smileyAddButton
                    .padding(.top, sortedMeals.isEmpty ? 20 : 30)
            } else {
                self.historicalDaySummary
                    .padding(.top, sortedMeals.isEmpty ? 20 : 30)
            }
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .center) { self.timelineLine }
        .onAppear { self.updateInsightCoachmark() }
        .onChange(of: self.hasInsightAvailable) { _, _ in
            self.updateInsightCoachmark()
        }
    }

    // MARK: - Meal Block

    @ViewBuilder
    private func mealBlockView(for meal: Meal) -> some View {
        if self.isToday {
            JournalBlockView(
                meal: meal,
                isBreathing: self.breathingMeals.contains(meal.id),
                onUpdate: { mealType, newItems in
                    self.mealActions.onUpdate(meal.id, mealType, newItems)
                },
                onLocalUpdate: { mealType, newItems in
                    self.mealActions.onLocalUpdate(meal.id, mealType, newItems)
                },
                onTimestampUpdate: { newTimestamp in
                    self.mealActions.onUpdateTimestamp(meal.id, newTimestamp)
                },
                onDelete: {
                    withAnimation(.spring()) {
                        self.mealActions.onDelete(meal.id)
                    }
                },
                recentMeals: self.recentMeals
            )
        } else {
            // Read-only view for historical days
            ReadOnlyMealCardView(meal: meal, onCopyMeal: self.mealActions.onCopy)
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
            .fill(Color.primary.opacity(AppTheme.Timeline.spineOpacity))
            .frame(width: AppTheme.Timeline.spineWidth)
            .padding(.top, 20)
    }

    // MARK: - Smiley Add Button (Today Only)

    private var smileyAddButton: some View {
        VStack(spacing: 16) {
            SmileyView(state: self.smileyState)
                .frame(width: 120, height: 120)
                .scaleEffect(self.isSmileyPulsing ? AppTheme.Animation.breathingScale : 1.0)
                .animation(
                    self.isSmileyPulsing ? AppTheme.Animation.breathingPulse : .default,
                    value: self.isSmileyPulsing
                )
                .overlay(alignment: .topTrailing) {
                    if self.hasInsightAvailable, self.briefingCardData == nil {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                            .offset(x: 4, y: -4)
                    }
                }
                .overlay(alignment: .top) {
                    if self.showInsightCoachmark {
                        self.insightCoachmark
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .offset(y: -44)
                    }
                }
                .onTapGesture {
                    if self.showInsightCoachmark {
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.showInsightCoachmark = false
                        }
                    }
                    self.onSmileyTap?()
                    SensoryService.shared.playNudge(style: .medium)
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    if self.showInsightCoachmark {
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.showInsightCoachmark = false
                        }
                    }
                    self.onSmileyLongPress?()
                }
                .onAppear {
                    self.updateSmileyPulse()
                }
                .onChange(of: self.meals.count) { _, _ in
                    self.updateSmileyPulse()
                }

            Text(self.hasInsightAvailable ? Strings.Timeline.tapToLogWithInsight : Strings.Timeline.tapToLog)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .kerning(self.hasInsightAvailable ? 1 : 2)
                .fixedSize()

            if let summary = self.daySummaryText {
                Text(summary)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("day-summary-line")
            }

            if TimelineAnimationState.shouldShowEmptyStateGreeting(
                mealCount: self.meals.count, isToday: self.isToday
            ) {
                Text(Strings.Timeline.emptyStateGreeting)
                    .font(.system(size: 12, design: .default))
                    .italic()
                    .foregroundColor(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("empty-state-greeting")
            }

            if TimelineAnimationState.shouldShowQuote(
                mealCount: self.meals.count, isToday: self.isToday
            ) {
                Text(QuoteService.getDailyQuote().text)
                    .font(.system(size: 11, design: .serif))
                    .italic()
                    .foregroundColor(.secondary.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(Strings.Timeline.quoteAccessibility)
            }
        }
        .accessibilityIdentifier("add-meal-button")
        .accessibilityLabel(self.hasInsightAvailable ? Strings.Accessibility.addMealWithInsight : Strings.Accessibility
            .addMealButton)
        .accessibilityHint(self.hasInsightAvailable ? Strings.Accessibility.addMealWithInsightHint : Strings
            .Accessibility.addMealHint)
    }

    /// Updates the smiley pulse state based on current meal count and day context.
    /// Called on appear and whenever meal count changes.
    private func updateSmileyPulse() {
        let shouldPulse = TimelineAnimationState.shouldPulse(
            mealCount: self.meals.count, isToday: self.isToday
        )
        if self.isSmileyPulsing != shouldPulse {
            self.isSmileyPulsing = shouldPulse
        }
    }

    /// One-line ambient summary shown above the smiley when the ViewModel provides an average score.
    /// Uses the pre-computed `averageHealthScore` parameter to keep averaging logic in one place (SSOT).
    private var daySummaryText: String? {
        guard self.isToday, let avg = self.averageHealthScore, self.meals.count >= 2 else { return nil }
        return Strings.Timeline.daySummary(avgScore: Int(avg * 100), mealCount: self.meals.count)
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
        }
        .padding(.vertical, 20)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.8 { return .green }
        if score >= 0.5 { return .blue }
        return .orange
    }

    // MARK: - Insight Coachmark

    private var insightCoachmark: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.tap")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            Text("Hold to view insight")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.75))
        )
        .accessibilityLabel("Hold the smiley to view insight")
    }

    private func updateInsightCoachmark() {
        guard self.isToday, self.hasInsightAvailable, !self.insightCoachmarkSeen else { return }
        self.insightCoachmarkSeen = true
        withAnimation(.easeOut(duration: 0.2)) {
            self.showInsightCoachmark = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.showInsightCoachmark = false
            }
        }
    }
}

// MARK: - Read-Only Meal Card

/// A simplified, non-editable meal card for historical views.
struct ReadOnlyMealCardView: View {
    // MARK: - Constants

    /// Base fill color — uses semantically adaptive background for light/dark mode
    static let cardFillColor: Color = AppTheme.MealCard.background

    // MARK: - Properties

    let meal: Meal

    /// Callback when user taps the copy button to duplicate meal to today
    var onCopyMeal: ((Meal) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                MealTypeTag(mealType: self.meal.mealType)

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

                // Copy to today button (only if meal has items)
                if !self.meal.items.isEmpty, self.onCopyMeal != nil {
                    Button {
                        SensoryService.shared.playNudge(style: .medium)
                        self.onCopyMeal?(self.meal)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("copy-meal-button-\(self.meal.id)")
                    .accessibilityLabel("Copy meal to today")
                    .accessibilityHint("Duplicates this meal to today's log")
                }

                // Health score indicator
                Circle()
                    .fill(self.scoreColor)
                    .frame(width: 8, height: 8)

                Text("\(Int(self.meal.healthScore * 100))%")
                    .font(.caption)
                    .foregroundColor(self.scoreColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Self.cardFillColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(self.cardBackground)
                }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(self.borderColor, lineWidth: 2)
        )
        .padding(.horizontal, 24)
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
            onSmileyTap: {}
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
                averageHealthScore: 0.4
            )
        )
    }
}
