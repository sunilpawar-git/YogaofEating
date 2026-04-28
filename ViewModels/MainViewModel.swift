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
    private var pendingMealCreation: Bool = false

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

    /// Tracks in-flight AI analysis tasks per meal so that rapid edits
    /// cancel the previous task and only the most-recent request wins.
    var aiTasks: [UUID: Task<Void, Never>] = [:]

    init(
        healthProfileService: HealthProfileServiceProtocol? = nil,
        logicService: MealLogicProvider? = nil,
        persistenceService: PersistenceServiceProtocol? = nil,
        historicalService: (any HistoricalDataServiceProtocol)? = nil,
        skipDataLoading: Bool = false
    ) {
        let healthService = healthProfileService ?? HealthProfileService()
        self.healthProfileService = healthService
        self.logicService = logicService ?? MealLogicService(healthProfileService: healthService)
        self.persistenceService = persistenceService ?? PersistenceService.shared
        let resolvedHistorical = historicalService ?? HistoricalDataService()
        self.historicalService = resolvedHistorical

        // Wire back-reference so HistoricalDataService.saveHistoricalData()
        // always delegates to the single canonical save path here.
        if let concrete = resolvedHistorical as? HistoricalDataService {
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

        // Local synchronous update for immediate feedback
        let healthScore = self.logicService.calculateHealthScore(for: items)
        self.meals[index].items = items
        self.meals[index].healthScore = healthScore
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

        // Trigger async AI analysis for refined scoring — cancel any in-flight task for this meal
        self.aiTasks[mealId]?.cancel()
        self.aiTasks[mealId] = Task {
            await self.performDeepAnalysis(for: mealId, items: items)
            self.aiTasks[mealId] = nil
        }
    }

    /// Updates meal type and items together.
    func updateMeal(_ mealId: UUID, mealType: MealType, items: [String], withFeedback: Bool = false) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        // Local synchronous update
        let healthScore = self.logicService.calculateHealthScore(for: items)
        self.meals[index].mealType = mealType
        self.meals[index].items = items
        self.meals[index].healthScore = healthScore
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

        // Trigger async AI analysis — cancel any in-flight task for this meal
        self.aiTasks[mealId]?.cancel()
        self.aiTasks[mealId] = Task {
            await self.performDeepAnalysis(for: mealId, items: items)
            self.aiTasks[mealId] = nil
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

        // 3. Save both current and historical data
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

    /// Handles the smiley tap action, checking for morning sleep context only.
    /// Flow:
    /// 1. If morning sleep context → Show sleep quality sheet → Then create meal
    /// 2. Otherwise → Create meal directly
    /// Note: End-of-Day feeling is now captured via a permanent pill on the timeline, not via smiley tap
    func handleSmileyTap() {
        if self.isMorningSleepContext() {
            self.pendingMealCreation = true
            self.showSleepQualitySheet = true
        } else {
            self.createNewMeal()
        }
    }

    /// Returns true if the End-of-Day pill should be shown on the timeline.
    /// Shows when: user has logged at least one meal AND has not logged overall feeling yet.
    var showEndOfDayPill: Bool {
        !self.meals.isEmpty && self.todaysFeeling == nil
    }

    /// Handles tap on the End-of-Day pill to show the feeling input sheet.
    func handleEndOfDayPillTap() {
        self.pendingMealCreation = false // No meal creation after this
        self.showOverallFeelingSheet = true
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

        // Still create the meal even if user skips
        if self.pendingMealCreation {
            self.pendingMealCreation = false
            self.createNewMeal()
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
}
