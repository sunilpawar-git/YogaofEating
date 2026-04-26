import SwiftUI

// MARK: - Today Reflection Data

/// Groups today's reflection-related data and callbacks to reduce parameter proliferation.
/// Only used when `isToday` is true.
struct TodayReflectionData {
    /// Today's logged sleep quality (for displaying badge)
    var sleepQuality: SleepQuality?

    /// Today's Apple HealthKit sleep data (for displaying in badge)
    var appleSleepData: SleepData?

    /// Today's logged overall feeling (for displaying badge)
    var feeling: ReflectionFeeling?

    /// Whether to show the End-of-Day pill (only for today when feeling not logged)
    var showEndOfDayPill: Bool = false

    /// Whether to show the morning mind check pill (after sleep quality)
    var showMorningMindCheckPill: Bool = false

    /// Today's morning mind check entries (for displaying badge)
    var morningMindCheck: [MindCheckEntry]?

    /// Callback when user taps to edit sleep quality badge
    var onEditSleep: (() -> Void)?

    /// Callback when user taps to edit overall feeling badge
    var onEditFeeling: (() -> Void)?

    /// Callback when user taps the End-of-Day pill
    var onEndOfDayTap: (() -> Void)?

    /// Callback when user taps the morning mind check pill
    var onMorningMindCheckTap: (() -> Void)?

    /// Creates an empty reflection data (for historical views or previews)
    static let empty = TodayReflectionData()
}

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

    /// Whether any insight is available (drives "HOLD FOR INSIGHT" hint text and long-press enable).
    var hasInsightAvailable: Bool = false

    /// Whether an *unread* insight exists (drives red dot indicator and coachmark).
    var hasUnreadInsight: Bool = false

    /// Grouped reflection data for today (sleep, feeling, mind check, and callbacks)
    var reflectionData: TodayReflectionData = .empty

    /// Grouped meal update actions (reduces callback proliferation)
    var mealActions: MealUpdateActions = .empty

    /// Recent meals from past 3 days for quick-add feature (only for today)
    var recentMeals: [Meal] = []

    /// Current AI-generated insight to display inline (for today only)
    var currentInsight: DailyInsight?

    /// Callback to dismiss the inline insight card
    var onInsightDismiss: (() -> Void)?

    /// Today's daily intention for alignment hints on meal cards
    var dailyIntention: String?

    /// Callback when user rates their focus level (1-3)
    var onFocusRate: ((Int) -> Void)?

    /// Whether focus has already been rated today
    var hasFocusRating: Bool = false

    // MARK: - Legacy Parameter Support (Deprecated)

    // These are kept for backward compatibility but internally map to reflectionData

    /// Today's logged sleep quality (for displaying badge)
    /// - Note: Prefer using `reflectionData.sleepQuality` instead
    var todaysSleepQuality: SleepQuality? { self.reflectionData.sleepQuality }

    /// Today's Apple HealthKit sleep data (for displaying in badge)
    /// - Note: Prefer using `reflectionData.appleSleepData` instead
    var appleSleepData: SleepData? { self.reflectionData.appleSleepData }

    /// Today's logged overall feeling (for displaying badge)
    /// - Note: Prefer using `reflectionData.feeling` instead
    var todaysFeeling: ReflectionFeeling? { self.reflectionData.feeling }

    /// Whether to show the End-of-Day pill
    /// - Note: Prefer using `reflectionData.showEndOfDayPill` instead
    var showEndOfDayPill: Bool { self.reflectionData.showEndOfDayPill }

    /// Whether to show the morning mind check pill
    /// - Note: Prefer using `reflectionData.showMorningMindCheckPill` instead
    var showMorningMindCheckPill: Bool { self.reflectionData.showMorningMindCheckPill }

    /// Today's morning mind check entries
    /// - Note: Prefer using `reflectionData.morningMindCheck` instead
    var todaysMorningMindCheck: [MindCheckEntry]? { self.reflectionData.morningMindCheck }

    // MARK: - State

    @State private var breathingMeals: Set<UUID> = []
    @State var showInsightCoachmark: Bool = false
    @State var coachmarkDismissTask: Task<Void, Never>?
    @AppStorage(StorageKeys.insightCoachmarkSeen) var insightCoachmarkSeen: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Day Ring progress summary
            if let snap = self.snapshot {
                self.dayRingHeader(for: snap)
                    .padding(.bottom, 12)
            }

            // Sleep badge at TOP of timeline (for today only)
            if self.isToday, let sleepQuality = self.todaysSleepQuality {
                self.sleepBadge(sleepQuality)
                    .padding(.bottom, 8)
            }

            // Morning mind check: pill or badge after sleep quality
            if self.isToday {
                if let morningEntries = self.todaysMorningMindCheck, !morningEntries.isEmpty {
                    MindCheckBadgeView(entries: morningEntries, context: .morning) {
                        // Tap to edit existing entries
                        self.reflectionData.onMorningMindCheckTap?()
                    }
                    .padding(.bottom, 16)
                } else if self.showMorningMindCheckPill {
                    MindCheckPillView {
                        self.reflectionData.onMorningMindCheckTap?()
                    }
                    .padding(.bottom, 16)
                }
            }

            // Inline insight card (shown after sleep + mind check, before meals)
            if self.isToday, let insight = self.currentInsight, !insight.isViewed {
                InsightCardView(insight: insight, onDismiss: self.onInsightDismiss)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 16)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
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

            // Focus check prompt (after 2+ meals, if not yet rated)
            if self.isToday, sortedMeals.count >= 2, !self.hasFocusRating,
               let onRate = self.onFocusRate
            {
                FocusCheckView(onRate: onRate)
                    .padding(.horizontal, 4)
                    .padding(.top, 12)
            }

            // Feeling badge above smiley (for today only, when logged)
            // OR End-of-Day pill when feeling not yet logged
            if self.isToday {
                if let feeling = self.todaysFeeling {
                    self.feelingBadge(feeling)
                        .padding(.top, 8)
                } else if self.showEndOfDayPill {
                    self.endOfDayPill
                        .padding(.top, 8)
                }
            }

            // Show appropriate bottom content based on whether it's today or historical
            if self.isToday {
                self.smileyAddButton
                    .padding(
                        .top,
                        (self.todaysFeeling != nil || self.showEndOfDayPill) ? 12 : (sortedMeals.isEmpty ? 20 : 30)
                    )
            } else {
                self.historicalDaySummary
                    .padding(.top, sortedMeals.isEmpty ? 20 : 30)
            }
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .center) { self.timelineLine }
        .onAppear { self.updateInsightCoachmark() }
        .onChange(of: self.hasUnreadInsight) { _, _ in
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
                recentMeals: self.recentMeals,
                dailyIntention: self.dailyIntention
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

    @State var isMindCheckExpanded: Bool = false
}
