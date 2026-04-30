import Combine
import Foundation
import OSLog
import SwiftUI

private let vmLogger = Logger(subsystem: "com.yogaofeating", category: "MainViewModel")

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

    /// Meals sorted by timestamp (computed once per change, not per render).
    /// Internal only — no SwiftUI view binds to this; views receive sorted meals via `meals` or `fastingPeriods`.
    private var sortedMeals: [Meal] = []

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
    private var pendingMealCreation: Bool = false

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

    /// Suggested sleep quality from Apple HealthKit (if available)
    @Published var suggestedSleepQuality: SleepQuality?

    /// Sleep data from Apple HealthKit (for display)
    @Published var appleSleepData: SleepData?

    // MARK: - AI Analysis Tracking

    /// Tracks meal IDs currently being analyzed to prevent concurrent duplicate requests.
    /// This addresses the "GTMSessionFetcher was already running" warning.
    var analysisInProgress: Set<UUID> = []

    /// Tracks in-flight AI analysis tasks per meal so that rapid edits
    /// cancel the previous task and only the most-recent request wins.
    var aiTasks: [UUID: Task<Void, Never>] = [:]

    // MARK: - Day Navigation (Phase 4)

    /// The currently selected date for viewing. Defaults to today.
    @Published var selectedDate: Date = .init()

    /// Maximum number of days the user can navigate back. Default: 30 days.
    static let maxDaysBack: Int = 30

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

    /// Cached formatter for the selected date display. Allocated once per VM instance
    /// rather than on every call to `formattedSelectedDate`.
    private let selectedDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMM yyyy"
        return f
    }()

    init(
        healthProfileService: HealthProfileServiceProtocol? = nil,
        logicService: MealLogicProvider? = nil,
        persistenceService: PersistenceServiceProtocol? = nil,
        historicalService: (any HistoricalDataServiceProtocol)? = nil,
        insightService: InsightGenerationServiceProtocol? = nil,
        skipDataLoading: Bool = false
    ) {
        let healthService = healthProfileService ?? HealthProfileService()
        let historicalSvc = historicalService ?? HistoricalDataService()
        self.healthProfileService = healthService
        self.logicService = logicService ?? AILogicService()
        self.persistenceService = persistenceService ?? PersistenceService.shared
        self.historicalService = historicalSvc
        self.insightService = insightService ?? InsightGenerationService(historicalService: historicalSvc)

        // Wire back-reference so HistoricalDataService.saveHistoricalData()
        // always delegates to the single canonical save path here.
        if let concrete = historicalSvc as? HistoricalDataService {
            concrete.mainViewModel = self
        }

        if !skipDataLoading {
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

            // If sleep quality is already logged today, fetch Apple sleep data for badge display
            if self.todaysSleepQuality != nil {
                self.fetchAppleSleepDataForBadge()
            }
        }
    }

    /// Fetches Apple sleep data for badge display (after sleep quality is already saved).
    /// Called on app load when sleep quality is already logged.
    private func fetchAppleSleepDataForBadge() {
        Task {
            do {
                _ = try await HealthKitService.shared.requestAuthorization()
                if let sleepData = try await HealthKitService.shared.fetchSleepData(for: Date()) {
                    await MainActor.run {
                        self.appleSleepData = sleepData
                        vmLogger
                            .debug(
                                "Loaded Apple sleep data for badge: \(sleepData.formattedDuration, privacy: .public)"
                            )
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
        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                self?.checkAndResetIfNewDay()
            }
        }
    }

    func checkAndResetIfNewDay() {
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
            vmLogger.debug("Skipping update - content unchanged after normalization")
            return
        }

        // Local synchronous update for immediate feedback
        let healthScore = self.logicService.calculateHealthScore(for: items)
        self.meals[index].items = items
        self.meals[index].healthScore = healthScore

        // Reset AI analyzed flag since content needs re-analysis
        self.meals[index].isAIAnalyzed = false

        self.saveData()
        vmLogger.debug("Local healthScore set to \(healthScore, privacy: .public)")

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
            vmLogger.debug("Local-only update: healthScore set to \(healthScore, privacy: .public)")
        } else {
            // Mark that content changed since last AI analysis
            self.meals[index].isAIAnalyzed = false
            vmLogger.debug("Local-only update: items changed, AI score invalidated")
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
            vmLogger.debug("Triggering AI analysis for meal updated locally")
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
            // Use average health score of all remaining meals
            let avgScore = self.meals.map(\.healthScore).reduce(0.0, +) / Double(self.meals.count)
            self.updateSmileyState(with: avgScore)
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
                SensoryService.shared.playNudge(style: healthScore < ScoringThresholds.unhealthy ? .heavy : .light)
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

        // Calculate average health score from all meals
        let totalScore = self.meals.map(\.healthScore).reduce(0.0, +)
        let avgScore = totalScore / Double(self.meals.count)

        self.updateSmileyState(with: avgScore, withFeedback: withFeedback)
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

    /// Returns today's sleep quality if logged.
    var todaysSleepQuality: SleepQuality? {
        self.todaysReflection?.sleepQuality
    }

    /// Returns today's overall feeling if logged.
    var todaysFeeling: ReflectionFeeling? {
        self.todaysReflection?.feeling
    }

    // MARK: - Context Detection (Phase 2 - User-Initiated Reflections)

    /// The hour before which sleep context is valid (noon = 12)
    static let morningCutoffHour: Int = 12

    /// Determines if the current smiley tap should show the sleep quality prompt.
    /// Returns true if: it's before noon, no meals logged yet (first tap), and no sleep logged today.
    /// - Parameter date: The current date/time to check against (defaults to now)
    /// - Returns: Whether to show the sleep quality prompt
    func isMorningSleepContext(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        // Must be before noon
        guard hour < Self.morningCutoffHour else { return false }

        // Must be first tap of the day (no meals yet)
        guard self.meals.isEmpty else { return false }

        // Must not have sleep quality logged today
        guard self.todaysSleepQuality == nil else { return false }

        return true
    }

    /// Determines if the current smiley tap should show the overall feeling prompt.
    /// Returns true if: user has logged at least one meal and no feeling logged today.
    /// - Returns: Whether to show the overall feeling prompt
    /// - Note: Deprecated - End-of-Day feeling is now captured via permanent pill, use `showEndOfDayPill` instead
    @available(*, deprecated, message: "Use showEndOfDayPill computed property instead")
    func isEveningFeelingContext() -> Bool {
        // Must have at least one meal logged
        guard !self.meals.isEmpty else { return false }

        // Must not have feeling logged today
        guard self.todaysFeeling == nil else { return false }

        return true
    }

    /// Saves sleep quality for today, merging with existing reflection if present.
    /// Also triggers insight generation and ensures Apple sleep data is available for badge.
    /// - Parameters:
    ///   - quality: The sleep quality to save
    ///   - date: When it was logged (defaults to now)
    func saveSleepQuality(_ quality: SleepQuality, at date: Date = Date()) {
        let newReflection = DailyReflection.withSleepQuality(quality, at: date)

        // Merge with existing reflection if present
        if let existing = self.todaysReflection {
            let merged = newReflection.merging(with: existing)
            self.historicalService.updateReflection(for: date, reflection: merged)
        } else {
            self.historicalService.updateReflection(for: date, reflection: newReflection)
        }

        // Fetch Apple sleep data for badge if not already available
        if self.appleSleepData == nil {
            self.fetchAppleSleepDataForBadge()
        }

        // Trigger insight generation after sleep is logged (Phase 2-4)
        self.triggerInsightGenerationIfNeeded(for: date)
    }

    /// Triggers insight generation if conditions are met.
    /// Conditions: No insight exists for today AND sleep quality is logged AND historical data exists.
    /// - Parameter date: The date to generate insight for
    private func triggerInsightGenerationIfNeeded(for date: Date) {
        // Phase 4: Don't regenerate if insight already exists for today
        if let existingInsight = self.currentInsight,
           Calendar.current.isDate(existingInsight.date, inSameDayAs: date)
        {
            return
        }

        // Trigger async insight generation with HealthKit sleep data
        Task {
            do {
                // Fetch HealthKit sleep data for the last 3 days (matching serverLookbackDays)
                let healthKitSleepData = await self.fetchHealthKitSleepDataForInsights(relativeTo: date)

                if let insight = try await self.insightService.generateInsight(
                    for: date,
                    healthKitSleepData: healthKitSleepData
                ) {
                    // Phase 3: Assign to currentInsight
                    self.currentInsight = insight
                }
            } catch {
                vmLogger.error("Insight generation failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Fetches HealthKit sleep data for the last N days for insight generation.
    /// - Parameter date: The reference date (typically today)
    /// - Returns: Dictionary mapping dates to their HealthKit sleep data
    private func fetchHealthKitSleepDataForInsights(relativeTo date: Date) async -> [Date: SleepData] {
        var sleepDataByDate: [Date: SleepData] = [:]
        let calendar = Calendar.current

        // Fetch sleep data for the last 3 days (matching serverLookbackDays in InsightGenerationService)
        for daysAgo in 0..<3 {
            guard let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: date) else { continue }

            do {
                if let sleepData = try await HealthKitService.shared.fetchSleepData(for: targetDate) {
                    sleepDataByDate[calendar.startOfDay(for: targetDate)] = sleepData
                    vmLogger.debug("Fetched HealthKit sleep data")
                }
            } catch {
                vmLogger.error("Failed to fetch HealthKit sleep data: \(error.localizedDescription, privacy: .public)")
                // Continue with other dates even if one fails
            }
        }

        return sleepDataByDate
    }

    /// Saves overall feeling for today, merging with existing reflection if present.
    /// - Parameters:
    ///   - feeling: The overall feeling to save
    ///   - date: When it was logged (defaults to now)
    func saveOverallFeeling(_ feeling: ReflectionFeeling, at date: Date = Date()) {
        let newReflection = DailyReflection.withFeeling(feeling, at: date)

        // Merge with existing reflection if present
        if let existing = self.todaysReflection {
            let merged = newReflection.merging(with: existing)
            self.historicalService.updateReflection(for: date, reflection: merged)
        } else {
            self.historicalService.updateReflection(for: date, reflection: newReflection)
        }
    }

    // MARK: - Smiley Tap Flow (Phase 4 - User-Initiated Reflections)

    /// Returns true if running UI tests. Used to bypass reflection flows during testing.
    private var isUITesting: Bool {
        CommandLine.arguments.contains("--uitesting")
    }

    /// Handles the smiley tap action, checking for morning sleep context only.
    /// Flow:
    /// 1. If morning sleep context → Show sleep quality sheet → Then create meal
    /// 2. Otherwise → Create meal directly
    /// Note: End-of-Day feeling is now captured via a permanent pill on the timeline, not via smiley tap
    /// During UI testing, skips all reflection checks and creates meals directly.
    func handleSmileyTap() {
        // Skip reflection flows during UI testing for simpler test scenarios
        if self.isUITesting {
            self.createNewMeal()
            return
        }

        if self.isMorningSleepContext() {
            self.pendingMealCreation = true
            self.showSleepQualitySheet = true
            // Fetch Apple HealthKit sleep data if available
            self.fetchAppleSleepData()
        } else {
            self.createNewMeal()
        }
    }

    /// Returns true if the End-of-Day pill should be shown on the timeline.
    /// Shows when: user has logged at least one meal AND has not logged overall feeling yet.
    var showEndOfDayPill: Bool {
        !self.meals.isEmpty && self.todaysFeeling == nil
    }

    /// Handles tap on the End-of-Day pill to show the appropriate sheet.
    /// Phase 3: If morning todos exist, shows EveningReviewView (holistic mindset capture).
    /// Otherwise, shows the feeling input directly.
    func handleEndOfDayPillTap() {
        self.pendingMealCreation = false // No meal creation after this

        // Check if morning todos exist - if so, show holistic evening review
        if let morningEntries = self.todaysMorningMindCheck, !morningEntries.isEmpty {
            self.isEndOfDayFlow = true // Enable feeling selection in EveningReviewView
            self.showEveningMindCheckSheet = true
        } else {
            // No todos, just ask for feeling
            self.showOverallFeelingSheet = true
        }
    }

    /// Completes the sleep quality input and proceeds with meal creation if pending.
    /// - Parameter quality: The selected sleep quality
    func completeSleepQualityInput(_ quality: SleepQuality) {
        self.saveSleepQuality(quality)
        self.showSleepQualitySheet = false

        if self.pendingMealCreation {
            self.pendingMealCreation = false
            self.createNewMeal()
        }
    }

    /// Dismisses the sleep quality sheet without saving.
    func dismissSleepQualityInput() {
        self.showSleepQualitySheet = false
        // Clear suggested sleep data when dismissed
        self.suggestedSleepQuality = nil
        self.appleSleepData = nil

        // Still create the meal even if user skips
        if self.pendingMealCreation {
            self.pendingMealCreation = false
            self.createNewMeal()
        }
    }

    /// Fetches sleep data from Apple HealthKit and suggests a sleep quality.
    /// This runs asynchronously and updates suggestedSleepQuality if data is available.
    private func fetchAppleSleepData() {
        Task {
            do {
                // Request authorization first
                _ = try await HealthKitService.shared.requestAuthorization()

                // Fetch sleep data for today
                if let sleepData = try await HealthKitService.shared.fetchSleepData(for: Date()) {
                    await MainActor.run {
                        self.appleSleepData = sleepData
                        self.suggestedSleepQuality = sleepData.sleepQuality
                        vmLogger.debug("Loaded Apple sleep data for badge")
                    }
                }
            } catch {
                vmLogger.error("Failed to fetch Apple sleep data: \(error.localizedDescription, privacy: .public)")
                // Silently fail - user can still manually select sleep quality
            }
        }
    }

    /// Completes the overall feeling input and proceeds with meal creation if pending.
    /// - Parameter feeling: The selected feeling
    func completeOverallFeelingInput(_ feeling: ReflectionFeeling) {
        self.saveOverallFeeling(feeling)
        self.showOverallFeelingSheet = false

        if self.pendingMealCreation {
            self.pendingMealCreation = false
            self.createNewMeal()
        }
    }

    /// Dismisses the overall feeling sheet without saving.
    func dismissOverallFeelingInput() {
        self.showOverallFeelingSheet = false

        // Still create the meal even if user skips
        if self.pendingMealCreation {
            self.pendingMealCreation = false
            self.createNewMeal()
        }
    }

    // MARK: - Day Navigation Methods (Phase 4)

    /// Returns true if the selected date is today.
    var isViewingToday: Bool {
        Calendar.current.isDateInToday(self.selectedDate)
    }

    /// Returns true if the user can navigate to the previous day (within maxDaysBack limit).
    var canNavigateToPreviousDay: Bool {
        self.selectedDayIndex < Self.maxDaysBack
    }

    /// Returns true if the user can navigate to the next day (not beyond today).
    var canNavigateToNextDay: Bool {
        !self.isViewingToday
    }

    /// Returns the number of days between the selected date and today (0 = today).
    var selectedDayIndex: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: self.selectedDate)
        let components = calendar.dateComponents([.day], from: selected, to: today)
        return max(0, components.day ?? 0)
    }

    /// Formatted string for the selected date (e.g., "Monday, 5 Jan 2026").
    /// Uses the cached `selectedDateFormatter` to avoid allocating a new formatter per call.
    var formattedSelectedDate: String {
        self.selectedDateFormatter.string(from: self.selectedDate)
    }

    /// Navigates to a specific date. Future dates are clamped to today.
    /// - Parameter date: The date to navigate to
    func navigateToDate(_ date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: date)

        // Clamp to today if trying to navigate to future
        if targetDay > today {
            self.selectedDate = today
        } else {
            self.selectedDate = targetDay
        }
    }

    /// Navigates to the previous day.
    func navigateToPreviousDay() {
        guard self.canNavigateToPreviousDay else { return }
        let calendar = Calendar.current
        if let previousDay = calendar.date(byAdding: .day, value: -1, to: self.selectedDate) {
            self.navigateToDate(previousDay)
        }
    }

    /// Navigates to the next day (towards today).
    func navigateToNextDay() {
        guard self.canNavigateToNextDay else { return }
        let calendar = Calendar.current
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: self.selectedDate) {
            self.navigateToDate(nextDay)
        }
    }

    /// Navigates back to today.
    func navigateToToday() {
        self.selectedDate = Calendar.current.startOfDay(for: Date())
    }

    /// Navigates to a day by index (0 = today, 1 = yesterday, etc.).
    /// - Parameter index: The number of days back from today
    func navigateToIndex(_ index: Int) {
        let calendar = Calendar.current
        let clampedIndex = max(0, min(index, Self.maxDaysBack))
        let today = calendar.startOfDay(for: Date())
        if let targetDate = calendar.date(byAdding: .day, value: -clampedIndex, to: today) {
            self.selectedDate = targetDate
        }
    }

    /// Returns the meals for the currently selected date.
    /// For today, returns current meals. For past days, returns historical meals.
    func mealsForSelectedDate() -> [Meal] {
        if self.isViewingToday {
            self.meals
        } else {
            self.snapshotForSelectedDate()?.meals ?? []
        }
    }

    /// Returns the snapshot for the currently selected date, if available.
    func snapshotForSelectedDate() -> DailySmileySnapshot? {
        self.historicalService.getSnapshot(for: self.selectedDate)
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

        // Trigger AI analysis for the copied meal — cancel any stale task first
        let copiedId = newMeal.id
        self.aiTasks[copiedId]?.cancel()
        self.aiTasks[copiedId] = Task {
            await self.performDeepAnalysis(for: copiedId, items: newMeal.items)
            self.aiTasks[copiedId] = nil
        }
    }
}
