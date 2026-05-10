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

    /// Calorie pill data for the today smiley button area. Nil hides the pill.
    var caloriePillData: CaloriePillData?

    /// Full detail data for the calorie detail sheet (today only). Nil for historical pills.
    var calorieDetailData: CalorieDetailData?

    // MARK: - State

    @State var breathingMeals: Set<UUID> = []
    @State var showInsightCoachmark: Bool = false
    @State var isSmileyPulsing: Bool = false
    @AppStorage(StorageKeys.insightCoachmarkSeen) var insightCoachmarkSeen: Bool = false

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

    // MARK: - Smiley and Historical sections extracted to DayTimelineView+SmileySection.swift
}

// ReadOnlyMealCardView extracted to ReadOnlyMealCardView.swift

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
