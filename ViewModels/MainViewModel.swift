import Combine
import Foundation
import SwiftUI

/// Protocol for persistence operations to enable testing
@MainActor
protocol PersistenceServiceProtocol {
    func load() -> PersistenceService.AppData?
    func save(meals: [Meal], smileyState: SmileyState, lastResetDate: Date, historicalData: HistoricalData)
    func deleteAll()
}

/// Central state manager for the Yoga of Eating app.
/// Strictly follows MVVM and handles interaction between View and Logic.
@MainActor
class MainViewModel: ObservableObject {
    @Published var smileyState: SmileyState = .neutral
    @Published var meals: [Meal] = [] {
        didSet { self.updateDerivedState() }
    }

    @Published var lastResetDate: Date = .init()

    /// Meals sorted by timestamp (computed once per change, not per render)
    @Published private(set) var sortedMeals: [Meal] = []

    /// Cached fasting periods between consecutive meals
    @Published private(set) var fastingPeriods: [FastingPeriod] = []

    // MARK: - End-of-Day Reflection (Phase 3)

    /// Controls visibility of the end-of-day reflection sheet
    @Published var showReflectionSheet: Bool = false

    /// The hour (24h format) after which reflection prompt should appear. Default: 8 PM (20:00)
    static let reflectionPromptHour: Int = 20

    // MARK: - User-Initiated Reflections (Phase 4 - Redesign)

    /// Controls visibility of the sleep quality input sheet (morning context)
    @Published var showSleepQualitySheet: Bool = false

    /// Controls visibility of the overall feeling input sheet (evening context)
    @Published var showOverallFeelingSheet: Bool = false

    /// Pending action to execute after reflection input is complete
    var pendingMealCreation: Bool = false

    // MARK: - Mind Check (Phase 3 - Mind Check Feature)

    /// Controls visibility of the morning mind check input sheet
    @Published var showMorningMindCheckSheet: Bool = false

    /// Controls visibility of the evening mind check input sheet
    @Published var showEveningMindCheckSheet: Bool = false

    /// Whether evening review is being shown from End-of-Day pill (includes feeling selection)
    @Published var isEndOfDayFlow: Bool = false

    /// Entries being edited (nil when creating new entries)
    @Published var editingMorningEntries: [MindCheckEntry]?

    // MARK: - Insights (Phase 6 - Peekaboo Star)

    /// Controls visibility of the insight bottom sheet
    @Published var showInsightSheet: Bool = false

    /// The current insight to display (generated when sleep is logged)
    @Published var currentInsight: DailyInsight?

    /// Aggregated weekly summary insight.
    @Published var currentWeeklyInsight: WeeklyInsight?

    /// Suggested sleep quality from Apple HealthKit (if available)
    @Published var suggestedSleepQuality: SleepQuality?

    /// Sleep data from Apple HealthKit (for display)
    @Published var appleSleepData: SleepData?

    // MARK: - Reflect Flow (Phase 1.1 Reboot)

    /// Controls visibility of the morning Reflect input sheet (energy + intention)
    @Published var showReflectSheet: Bool = false

    // MARK: - AI Analysis Tracking

    /// Tracks meal IDs currently being analyzed to prevent concurrent duplicate requests.
    /// This addresses the "GTMSessionFetcher was already running" warning.
    var analysisInProgress: Set<UUID> = []

    // MARK: - Day Navigation (Phase 4)

    /// The currently selected date for viewing. Defaults to today.
    @Published var selectedDate: Date = .init()

    /// Maximum number of days the user can navigate back. Default: 30 days.
    // Moved to MainViewModel+DayNavigation.swift

    /// Updates derived state (sorted meals and fasting periods) when meals change
    private func updateDerivedState() {
        self.sortedMeals = self.meals.sorted { $0.timestamp < $1.timestamp }
        self.fastingPeriods = FastingLogicService.calculateFastingPeriods(from: self.sortedMeals)
    }

    let logicService: MealLogicProvider
    let persistenceService: PersistenceServiceProtocol
    let historicalService: any HistoricalDataServiceProtocol
    let healthProfileService: HealthProfileServiceProtocol
    let insightService: InsightGenerationServiceProtocol
    private var resetMonitorTask: Task<Void, Never>?

    init(
        healthProfileService: HealthProfileServiceProtocol? = nil,
        logicService: MealLogicProvider? = nil,
        persistenceService: PersistenceServiceProtocol? = nil,
        historicalService: (any HistoricalDataServiceProtocol)? = nil,
        insightService: InsightGenerationServiceProtocol? = nil
    ) {
        let healthService = healthProfileService ?? HealthProfileService()
        let historicalSvc = historicalService ?? HistoricalDataService()
        self.healthProfileService = healthService
        self.logicService = logicService ?? AILogicService()
        self.persistenceService = persistenceService ?? PersistenceService.shared
        self.historicalService = historicalSvc
        self.insightService = insightService ?? InsightGenerationService(historicalService: historicalSvc)

        // Skip data loading and monitoring if unit testing to avoid interference
        if NSClassFromString("XCTestCase") == nil {
            self.loadData()
            self.setupResetMonitoring()
        }
    }

    /// Loads persisted data or starts fresh
    func loadData() {
        if let data = self.persistenceService.load() {
            self.meals = data.meals
            self.smileyState = data.smileyState
            self.lastResetDate = data.lastResetDate
            self.historicalService.historicalData = data.historicalData

            // Still check if we need to reset for a new day since the last save
            self.checkAndResetIfNewDay()

            // Restore today's persisted insight
            if let snapshot = self.historicalService.getSnapshot(for: Date()) {
                self.currentInsight = snapshot.dailyInsight
            }

            self.refreshWeeklyInsight()

            // If sleep quality is already logged today, fetch Apple sleep data for badge display
            if self.todaysSleepQuality != nil {
                self.fetchAppleSleepDataForBadge()
            }
        }
    }

    /// Fetches Apple sleep data for badge display (after sleep quality is already saved).
    /// Called on app load when sleep quality is already logged.
    func fetchAppleSleepDataForBadge() {
        Task {
            do {
                _ = try await HealthKitService.shared.requestAuthorization()
                if let sleepData = try await HealthKitService.shared.fetchSleepData(for: Date()) {
                    await MainActor.run {
                        self.appleSleepData = sleepData
                        print("📊 Loaded Apple sleep data for badge: \(sleepData.formattedDuration)")
                    }
                }
            } catch {
                // Silently fail - badge will just not show Apple metrics
            }
        }
    }

    /// Saves current state
    func saveData() {
        self.persistenceService.save(
            meals: self.meals,
            smileyState: self.smileyState,
            lastResetDate: self.lastResetDate,
            historicalData: self.historicalService.historicalData
        )
    }

    /// Periodically checks if the day has changed to reset the slate.
    private func setupResetMonitoring() {
        self.resetMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                self?.checkAndResetIfNewDay()
            }
        }
    }

    deinit {
        resetMonitorTask?.cancel()
    }

    private func checkAndResetIfNewDay() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(self.lastResetDate) {
            self.resetDay()
            self.lastResetDate = Date()
            self.saveData()
        }
    }

    /// Adds a new empty meal entry. Triggered by tapping the Smiley.
    func createNewMeal() {
        self.createNewMeal(mealType: nil)
    }

    /// Adds a new meal entry with optional meal type (auto-detected if nil).
    func createNewMeal(mealType: MealType? = nil) {
        self.checkAndResetIfNewDay()
        let newMeal = Meal(mealType: mealType)
        withAnimation(.spring()) {
            self.meals.append(newMeal)
        }
        self.saveData()
    }

    /// Updates an existing meal's description and recalculates health.
    /// Legacy method for backward compatibility - converts to items array.
    func updateMeal(_ mealId: UUID, description: String) {
        self.updateMealItems(mealId, items: description.isEmpty ? [] : [description])
    }

    /// Updates an existing meal's items and recalculates health.
    func updateMealItems(_ mealId: UUID, items: [String], withFeedback: Bool = false) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        // Check if items meaningfully changed (normalized comparison to handle whitespace)
        let contentChanged = Self.contentMeaningfullyChanged(old: self.meals[index].items, new: items)

        // Only update items and recalculate local score if content actually changed
        // This prevents overwriting AI scores with local scores on redundant updates
        guard contentChanged else {
            print("⏭️ Skipping update - content unchanged after normalization")
            return
        }

        // Local synchronous update for immediate feedback
        let healthScore = self.logicService.calculateHealthScore(for: items)
        self.meals[index].items = items
        self.meals[index].healthScore = healthScore

        // Reset AI analyzed flag since content needs re-analysis
        self.meals[index].isAIAnalyzed = false

        self.saveData()
        print("📝 Local healthScore set to: \(healthScore)")

        // Play personalized haptic feedback based on health score and user risk level
        if withFeedback, let profile = self.healthProfileService.getUserHealthProfile() {
            SensoryService.shared.playMealFeedbackHaptic(
                for: healthScore,
                riskLevel: profile.riskLevel,
                userDefaults: nil
            )
        }

        // Immediately update smiley state with current meal scores
        self.updateSmileyStateFromAllMeals(withFeedback: withFeedback)

        // Trigger AI analysis for new items
        Task {
            await self.performDeepAnalysis(for: mealId, items: items)
        }
    }

    /// Updates meal items locally WITHOUT triggering AI analysis.
    /// Use this for real-time updates during typing to provide immediate local feedback.
    /// AI analysis should be triggered separately via explicit user action (Done button, focus loss).
    func updateMealItemsLocalOnly(_ mealId: UUID, items: [String]) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        // Check if items meaningfully changed (normalized comparison to handle whitespace)
        let contentChanged = Self.contentMeaningfullyChanged(old: self.meals[index].items, new: items)

        // Only update if content actually changed
        guard contentChanged else { return }

        // Update items
        self.meals[index].items = items

        // Only recalculate local score if meal hasn't been AI-analyzed yet
        // This preserves AI scores during typing - they'll be re-analyzed on "done"
        if !self.meals[index].isAIAnalyzed {
            let healthScore = self.logicService.calculateHealthScore(for: items)
            self.meals[index].healthScore = healthScore
            print("📝 Local-only update: healthScore set to \(healthScore)")
        } else {
            // Mark that content changed since last AI analysis
            self.meals[index].isAIAnalyzed = false
            print("📝 Local-only update: items changed, AI score invalidated")
        }

        self.saveData()
    }

    /// Explicitly triggers AI analysis for a meal.
    /// Call this when user performs a "done" action (focus loss, Done button, Return key).
    /// This resets the isAIAnalyzed flag and calls performDeepAnalysis.
    func triggerAIAnalysisForMeal(_ mealId: UUID) async {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        // Reset the AI analyzed flag to allow re-analysis
        self.meals[index].isAIAnalyzed = false
        self.saveData()

        // Get current items and trigger analysis
        let items = self.meals[index].items
        await self.performDeepAnalysis(for: mealId, items: items)
    }

    /// Updates meal type and items together.
    /// Called on "done" actions (focus loss, Done button, Return key) - always triggers AI analysis
    /// if the meal hasn't been AI-analyzed yet.
    func updateMeal(_ mealId: UUID, mealType: MealType, items: [String], withFeedback: Bool = false) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        // Check if items meaningfully changed (normalized comparison to handle whitespace)
        let contentChanged = Self.contentMeaningfullyChanged(old: self.meals[index].items, new: items)
        let mealTypeChanged = self.meals[index].mealType != mealType
        let needsAIAnalysis = !self.meals[index].isAIAnalyzed && !items.isEmpty

        // Update meal type if changed
        if mealTypeChanged {
            self.meals[index].mealType = mealType
        }

        // Only recalculate local score if items meaningfully changed
        if contentChanged {
            let healthScore = self.logicService.calculateHealthScore(for: items)
            self.meals[index].items = items
            self.meals[index].healthScore = healthScore
            // Reset AI analyzed flag since content needs re-analysis
            self.meals[index].isAIAnalyzed = false

            self.saveData()

            // Play personalized haptic feedback based on health score and user risk level
            if withFeedback, let profile = self.healthProfileService.getUserHealthProfile() {
                SensoryService.shared.playMealFeedbackHaptic(
                    for: healthScore,
                    riskLevel: profile.riskLevel,
                    userDefaults: nil
                )
            }

            // Immediately update smiley state with current meal scores
            self.updateSmileyStateFromAllMeals(withFeedback: withFeedback)

            // Trigger AI analysis for new items
            Task {
                await self.performDeepAnalysis(for: mealId, items: items)
            }
        } else if mealTypeChanged {
            // Only meal type changed, just save
            self.saveData()
        } else if needsAIAnalysis {
            // Content was already updated locally, but AI analysis hasn't run yet
            // This happens when local updates occurred during typing, then user triggers "done"
            print("🔄 Triggering AI analysis for meal that was updated locally")
            Task {
                await self.triggerAIAnalysisForMeal(mealId)
            }
        }
    }

    /// Updates a meal's timestamp (for user-edited time).
    /// Does not trigger AI re-analysis since content hasn't changed.
    func updateMealTimestamp(_ mealId: UUID, timestamp: Date) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        self.meals[index].timestamp = timestamp
        self.saveData()
    }

    /// Deletes a meal entry and recalculates smiley state.
    func deleteMeal(_ mealId: UUID) {
        self.meals.removeAll { $0.id == mealId }

        SensoryService.shared.playNudge(style: .soft)

        if self.meals.isEmpty {
            withAnimation(.spring()) {
                self.smileyState = .neutral
            }
        } else {
            self.updateSmileyState(with: self.meals.averageHealthScore)
        }
        self.saveData()
    }

    func updateSmileyState(with healthScore: Double, withFeedback: Bool = true) {
        let nextState = self.logicService.calculateNextState(
            from: self.smileyState,
            healthScore: healthScore
        )

        // Only provide haptic feedback when explicitly requested (e.g., after user finishes typing)
        // Note: Sounds are disabled as they were found to be irritating during typing
        if withFeedback {
            // Check user preferences before playing feedback
            // Default to true if not explicitly set
            let hapticsEnabled = UserDefaults.standard.object(forKey: StorageKeys.hapticsEnabled) as? Bool ?? true

            if hapticsEnabled {
                SensoryService.shared.playNudge(style: healthScore < 0.4 ? .heavy : .light)
            }
            // Sound feedback removed - was irritating during text input
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            self.smileyState = nextState
        }
    }

    /// Updates smiley state based on all current meals' health scores.
    private func updateSmileyStateFromAllMeals(withFeedback: Bool = false) {
        guard !self.meals.isEmpty else {
            withAnimation(.spring()) {
                self.smileyState = .neutral
            }
            return
        }

        self.updateSmileyState(with: self.meals.averageHealthScore, withFeedback: withFeedback)
    }

    /// Resets the day's progress (at midnight or via manual reset).
    func resetDay() {
        // 1. Archive current day's data BEFORE clearing
        self.historicalService.archiveCurrentDay(
            meals: self.meals,
            state: self.smileyState,
            date: self.lastResetDate
        )

        // 2. Reset for new day
        withAnimation(.easeOut) {
            self.smileyState = .neutral
            self.meals = []
        }

        // 3. Clear current insight (new day, new insight)
        self.currentInsight = nil

        // 4. Save both current and historical data
        self.saveData()
    }

    /// Completely deletes all app data including meals, history, and resets to factory state.
    /// This is a destructive operation and cannot be undone.
    func deleteAllData() {
        // 1. Clear in-memory state
        withAnimation(.easeOut) {
            self.smileyState = .neutral
            self.meals = []
            self.lastResetDate = Date()
        }

        // 2. Clear historical data
        self.historicalService.clearAllData()

        // 3. Delete persistence file
        self.persistenceService.deleteAll()

        // 4. Clear UserDefaults keys (using centralized StorageKeys)
        for key in StorageKeys.allKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        // 5. Cancel any scheduled notifications
        NotificationManager.shared.cancelAllNotifications()
    }

    // MARK: - End-of-Day Reflection Methods (Legacy - Deprecated)

    /// Determines if the user should be prompted for an end-of-day reflection.
    /// Returns true if: it's after the prompt hour, user has logged meals, and no reflection exists for today.
    /// - Parameter date: The current date/time to check against (defaults to now)
    /// - Returns: Whether to show the reflection prompt
    /// - Note: Deprecated - Use `isMorningSleepContext()` and `isEveningFeelingContext()` instead
    @available(*, deprecated, message: "Use isMorningSleepContext() and isEveningFeelingContext() instead")
    func shouldPromptReflection(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        // Must be after the configured prompt hour (default 8 PM)
        guard hour >= Self.reflectionPromptHour else { return false }

        // Must have at least one meal logged today
        guard !self.meals.isEmpty else { return false }

        // Must not already have a reflection for today
        guard self.todaysReflection == nil else { return false }

        return true
    }

    /// Saves the user's end-of-day reflection and dismisses the sheet.
    /// - Parameter reflection: The reflection to save
    func saveReflection(_ reflection: DailyReflection) {
        let today = Date()
        self.historicalService.updateReflection(for: today, reflection: reflection)
        self.showReflectionSheet = false
    }

    /// Dismisses the reflection sheet without saving.
    func skipReflection() {
        self.showReflectionSheet = false
    }

    /// Triggers the reflection prompt if conditions are met.
    /// Call this when the view appears to check if reflection should be shown.
    /// - Parameter date: The current date/time to check against (defaults to now)
    /// - Note: Deprecated - Use `handleSmileyTap()` for user-initiated reflections instead
    @available(*, deprecated, message: "Use handleSmileyTap() for user-initiated reflections instead")
    func triggerReflectionPromptIfNeeded(at date: Date = Date()) {
        if self.shouldPromptReflection(at: date) {
            self.showReflectionSheet = true
        }
    }

    /// Returns today's reflection if one has been saved.
    var todaysReflection: DailyReflection? {
        let today = Date()
        return self.historicalService.getSnapshot(for: today)?.reflection
    }

    /// Returns today's snapshot for display (e.g. smiley state, meals for history).
    var todaysSnapshot: DailySmileySnapshot? {
        self.historicalService.getSnapshot(for: Date())
    }

    /// Returns the snapshot for a given historical date.
    func snapshot(for date: Date) -> DailySmileySnapshot? {
        self.historicalService.getSnapshot(for: date)
    }

    /// Returns today's sleep quality if logged.
    var todaysSleepQuality: SleepQuality? {
        self.todaysReflection?.sleepQuality
    }

    /// Returns today's overall feeling if logged.
    var todaysFeeling: ReflectionFeeling? {
        self.todaysReflection?.feeling
    }

    /// Returns today's daily intention if set.
    var todaysIntention: String? {
        self.todaysReflection?.dailyIntention
    }

    /// Returns today's morning energy level if logged.
    var todaysEnergyLevel: Int? {
        self.todaysReflection?.morningEnergyLevel
    }

    var todaysFocusRating: Int? {
        self.todaysReflection?.focusRating
    }

    /// Saves a mid-day focus rating (1-3), merging with existing reflection.
    func saveFocusRating(_ rating: Int) {
        let clamped = min(3, max(1, rating))
        let date = Date()
        let focusReflection = DailyReflection(focusRating: clamped, timestamp: date)

        if let existing = self.todaysReflection {
            let merged = focusReflection.merging(with: existing)
            self.historicalService.updateReflection(for: date, reflection: merged)
        } else {
            self.historicalService.updateReflection(for: date, reflection: focusReflection)
        }

        self.saveData()
    }

    // MARK: - Recent Meals & Copy Meal (Repeat Meal Feature)

    /// Returns unique meals from the past 3 days for quick-add suggestions.
    /// Deduplicates by normalized items content (lowercased, sorted).
    /// Returns max 8 meals, most recent first.
    func getRecentUniqueMeals() -> [Meal] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var allMeals: [Meal] = []

        // Collect meals from past 3 days
        for daysAgo in 1...3 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            if let snapshot = self.historicalService.getSnapshot(for: date) {
                allMeals.append(contentsOf: snapshot.meals)
            }
        }

        // Deduplicate by normalized items (lowercased, sorted, joined)
        var seenKeys = Set<String>()
        var uniqueMeals: [Meal] = []

        // Sort by timestamp descending (most recent first)
        let sortedMeals = allMeals.sorted { $0.timestamp > $1.timestamp }

        for meal in sortedMeals {
            // Skip empty meals
            guard !meal.items.isEmpty else { continue }

            // Create normalized key for deduplication
            let normalizedKey = meal.items
                .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                .sorted()
                .joined(separator: "|")

            if !seenKeys.contains(normalizedKey) {
                seenKeys.insert(normalizedKey)
                uniqueMeals.append(meal)
            }

            // Limit to 8 meals
            if uniqueMeals.count >= 8 {
                break
            }
        }

        return uniqueMeals
    }

    /// Copies a historical meal to today with a fresh ID and current timestamp.
    /// Preserves meal type and items from the original meal.
    /// - Parameter meal: The historical meal to copy
    func copyMealToToday(_ meal: Meal) {
        self.checkAndResetIfNewDay()

        let newMeal = Meal(
            id: UUID(),
            timestamp: Date(),
            mealType: meal.mealType,
            items: meal.items,
            healthScore: meal.healthScore,
            isAIAnalyzed: false // Will be re-analyzed
        )

        withAnimation(.spring()) {
            self.meals.append(newMeal)
        }
        self.saveData()

        // Trigger AI analysis for the copied meal
        Task {
            await self.performDeepAnalysis(for: newMeal.id, items: newMeal.items)
        }
    }
}
