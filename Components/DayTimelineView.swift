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

    /// Whether an insight is available (for showing red dot indicator)
    var hasInsightAvailable: Bool = false

    /// Grouped reflection data for today (sleep, feeling, mind check, and callbacks)
    var reflectionData: TodayReflectionData = .empty

    /// Grouped meal update actions (reduces callback proliferation)
    var mealActions: MealUpdateActions = .empty

    /// Recent meals from past 3 days for quick-add feature (only for today)
    var recentMeals: [Meal] = []

    /// Pre-computed average health score for the day summary line (today only, >= 2 meals).
    /// Provided by the ViewModel to avoid duplicating averaging logic inside the view.
    /// Nil means the summary line is not shown.
    var averageHealthScore: Double?

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
    @State private var showInsightCoachmark: Bool = false
    @State private var isSmileyPulsing: Bool = false
    @AppStorage(StorageKeys.insightCoachmarkSeen) private var insightCoachmarkSeen: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
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

    // MARK: - Reflection Badges (Today Only)

    private func sleepBadge(_ quality: SleepQuality) -> some View {
        ReflectionBadgeView(
            type: .sleep(quality),
            isTappable: true,
            onTap: {
                self.reflectionData.onEditSleep?()
            },
            sleepData: self.appleSleepData
        )
    }

    private func feelingBadge(_ feeling: ReflectionFeeling) -> some View {
        ReflectionBadgeView(
            type: .feeling(feeling),
            isTappable: true,
            onTap: {
                self.reflectionData.onEditFeeling?()
            }
        )
    }

    // MARK: - End-of-Day Pill (Today Only, When Feeling Not Logged)

    private var endOfDayPill: some View {
        Button(action: {
            self.reflectionData.onEndOfDayTap?()
            SensoryService.shared.playNudge(style: .light)
        }) {
            HStack(spacing: 6) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.purple.opacity(0.8))

                Text("End of Day")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.purple.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("end-of-day-pill")
        .accessibilityLabel("End of Day")
        .accessibilityHint("Tap to log how you felt today")
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
                    if self.hasInsightAvailable {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
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

            // Show reflection if available
            if let reflection = self.snapshot?.reflection {
                self.reflectionSummary(reflection)
            }

            // Show mind check entries if available (Phase 1)
            if let snapshot = self.snapshot,
               snapshot.hasMorningMindCheck || snapshot.hasEveningMindCheck
            {
                self.historicalMindCheckSection(snapshot: snapshot)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Historical Mind Check Section

    @State private var isMindCheckExpanded: Bool = false

    @ViewBuilder
    private func historicalMindCheckSection(snapshot: DailySmileySnapshot) -> some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal, 40)

            // Expandable header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isMindCheckExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(Strings.MindCheck.Historical.mindCheckSectionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: self.isMindCheckExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
            }
            .buttonStyle(.plain)

            // Expandable content
            if self.isMindCheckExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Morning todos
                    if let morningEntries = snapshot.morningMindCheck, !morningEntries.isEmpty {
                        self.historicalEntriesGroup(
                            header: Strings.MindCheck.Historical.morningHeader,
                            entries: morningEntries,
                            showCompletionStatus: true
                        )
                    }

                    // Evening entries
                    if let eveningEntries = snapshot.eveningMindCheck, !eveningEntries.isEmpty {
                        self.historicalEntriesGroup(
                            header: Strings.MindCheck.Historical.eveningHeader,
                            entries: eveningEntries,
                            showCompletionStatus: false
                        )
                    }
                }
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Strings.MindCheck.Historical.mindCheckSectionTitle)
    }

    @ViewBuilder
    private func historicalEntriesGroup(
        header: String,
        entries: [MindCheckEntry],
        showCompletionStatus: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            ForEach(entries) { entry in
                HStack(spacing: 8) {
                    // Category emoji
                    Text(entry.category.emoji)
                        .font(.system(size: 14))

                    // Entry text
                    Text(entry.text)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Spacer()

                    // Completion status for todos
                    if showCompletionStatus, entry.category == .todo {
                        if entry.isAccomplished == true {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(Strings.MindCheck.Historical.completed)
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text(Strings.MindCheck.Historical.notCompleted)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.03))
                )
            }
        }
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
                .fill(.ultraThinMaterial)
        )
        .background(
            // White overlay for consistency with today's cards (works in both light/dark mode)
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.4))
        )
        .background(
            // Subtle tint overlay based on health score
            RoundedRectangle(cornerRadius: 16)
                .fill(self.cardBackground)
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
            onSmileyTap: { print("Smiley tapped") },
            reflectionData: TodayReflectionData(
                sleepQuality: .good,
                feeling: .calm
            )
        )
    }
}

#Preview("Today Timeline - With Apple Sleep Data") {
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
            reflectionData: TodayReflectionData(
                sleepQuality: .good,
                appleSleepData: SleepData(
                    sleepDuration: 7.5 * 3600,
                    timeInBed: 8 * 3600,
                    sleepStart: nil,
                    sleepEnd: nil,
                    sleepScore: 85
                ),
                feeling: .calm
            )
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
                reflection: DailyReflection(feeling: .heavy, sleepQuality: .poor, note: "Overate"),
                morningMindCheck: [
                    MindCheckEntry(category: .todo, text: "Exercise", context: .morning, isAccomplished: true),
                    MindCheckEntry(category: .todo, text: "Read book", context: .morning, isAccomplished: false)
                ],
                eveningMindCheck: [
                    MindCheckEntry(category: .gratefulFor, text: "Good health", context: .evening)
                ]
            )
        )
    }
}
