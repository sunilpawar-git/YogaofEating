import Foundation
import OSLog
import SwiftUI

private let crudLogger = Logger(subsystem: "com.yogaofeating", category: "MealCRUD")

// MARK: - Meal CRUD, Smiley State, Day Reset

extension MainViewModel {
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

    /// - Note: Prefer `updateMeal(_:mealType:items:)` — this overload bypasses meal-type tracking.
    @available(*, deprecated, renamed: "updateMeal(_:mealType:items:)")
    func updateMeal(_ mealId: UUID, description: String) {
        self.updateMealItems(mealId, items: description.isEmpty ? [] : [description])
    }

    /// Updates an existing meal's items and recalculates health.
    /// Validates and sanitizes input before persistence — mirrors the security contract of updateMeal.
    func updateMealItems(_ mealId: UUID, items: [String], withFeedback: Bool = false) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        let nonEmpty = items.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !nonEmpty.isEmpty else { return }

        let joined = nonEmpty.joined(separator: ", ")
        switch InputValidator.validateMealDescription(joined) {
        case let .failure(error):
            self.lastValidationError = error
            self.showValidationErrorAlert = true
            return
        case .success:
            break
        }

        let sanitizedItems = InputValidator.sanitizeMealItems(nonEmpty)
        guard !sanitizedItems.isEmpty else { return }

        let contentChanged = Self.contentMeaningfullyChanged(old: self.meals[index].items, new: sanitizedItems)
        guard contentChanged else {
            crudLogger.debug("Skipping update - content unchanged after normalization")
            return
        }

        let healthScore = self.logicService.calculateHealthScore(for: sanitizedItems)
        self.meals[index].items = sanitizedItems
        self.meals[index].healthScore = healthScore
        self.meals[index].isAIAnalyzed = false

        self.saveData()

        if withFeedback, let profile = self.healthProfileService.getUserHealthProfile() {
            SensoryService.shared.playMealFeedbackHaptic(
                for: healthScore,
                riskLevel: profile.riskLevel,
                userDefaults: nil
            )
        }

        self.updateSmileyStateFromAllMeals(withFeedback: withFeedback)
        self.synthesisScheduler.schedule(.mealUpdated)

        self.aiCoordinator.analyzeIfNeeded(
            mealId: mealId,
            items: sanitizedItems,
            in: self.makeAnalysisContext(mealId: mealId)
        )
    }

    /// Explicitly triggers AI analysis for a meal using its currently-stored items.
    /// Items are read from the ViewModel (already validated/sanitized on write).
    /// `performDeepAnalysis` re-validates length and pattern before the Firebase call.
    func triggerAIAnalysisForMeal(_ mealId: UUID) async {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        self.meals[index].isAIAnalyzed = false
        self.saveData()

        let items = self.meals[index].items
        await self.performDeepAnalysis(for: mealId, items: items)
    }

    /// Updates meal type and items together.
    /// Called on checkmark tap — the sole submission path. Validates input, then saves and triggers AI.
    func updateMeal(_ mealId: UUID, mealType: MealType, items: [String], withFeedback: Bool = false) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        // Pre-filter: whitespace-only strings are treated as empty (no alert, silent no-op).
        let nonEmpty = items.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !nonEmpty.isEmpty else { return }

        let joined = nonEmpty.joined(separator: ", ")
        switch InputValidator.validateMealDescription(joined) {
        case let .failure(error):
            self.lastValidationError = error
            self.showValidationErrorAlert = true
            return
        case .success:
            break
        }

        // Sanitize each item individually so stored data matches what was validated.
        // This strips null bytes and C0/C1 control characters that pass pattern checks.
        let sanitizedItems = InputValidator.sanitizeMealItems(nonEmpty)
        guard !sanitizedItems.isEmpty else { return }

        let contentChanged = Self.contentMeaningfullyChanged(old: self.meals[index].items, new: sanitizedItems)
        let mealTypeChanged = self.meals[index].mealType != mealType
        let needsAIAnalysis = !self.meals[index].isAIAnalyzed

        if mealTypeChanged {
            self.meals[index].mealType = mealType
        }

        if contentChanged {
            let healthScore = self.logicService.calculateHealthScore(for: sanitizedItems)
            self.meals[index].items = sanitizedItems
            self.meals[index].healthScore = healthScore
            self.meals[index].isAIAnalyzed = false

            self.saveData()

            if withFeedback, let profile = self.healthProfileService.getUserHealthProfile() {
                SensoryService.shared.playMealFeedbackHaptic(
                    for: healthScore,
                    riskLevel: profile.riskLevel,
                    userDefaults: nil
                )
            }

            self.updateSmileyStateFromAllMeals(withFeedback: withFeedback)
            self.synthesisScheduler.schedule(.mealUpdated)

            self.aiCoordinator.analyzeIfNeeded(
                mealId: mealId,
                items: sanitizedItems,
                in: self.makeAnalysisContext(mealId: mealId)
            )
        } else if mealTypeChanged {
            self.saveData()
        } else if needsAIAnalysis {
            crudLogger.debug("Triggering AI analysis for unchanged meal content")
            self.aiCoordinator.analyzeIfNeeded(
                mealId: mealId,
                items: self.meals.first(where: { $0.id == mealId })?.items ?? [],
                in: self.makeAnalysisContext(mealId: mealId)
            )
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
            // Use the same AI-analyzed-only path as reanalyzeAllMealsForSmileyState
            // to keep smiley state consistent on days with mixed analyzed/unanalyzed meals.
            let analyzedMeals = self.meals.filter(\.isAIAnalyzed)
            if analyzedMeals.isEmpty {
                withAnimation(.spring()) {
                    self.smileyState = .neutral
                }
            } else {
                let avgScore = analyzedMeals.map(\.healthScore).reduce(0.0, +) / Double(analyzedMeals.count)
                self.updateSmileyState(with: avgScore)
            }
        }
        self.saveData()
    }

    // MARK: - Smiley State

    func updateSmileyState(with healthScore: Double, withFeedback: Bool = true) {
        let nextState = self.logicService.calculateNextState(
            from: self.smileyState,
            healthScore: healthScore
        )

        if withFeedback {
            let hapticsEnabled = UserDefaults.standard.object(forKey: StorageKeys.hapticsEnabled) as? Bool ?? true
            if hapticsEnabled {
                SensoryService.shared.playNudge(style: healthScore < ScoringThresholds.unhealthy ? .heavy : .light)
            }
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            self.smileyState = nextState
        }
    }

    /// Updates smiley state using the DailySynthesisEngine (all four data streams).
    /// Falls back to neutral if no data is present.
    func updateSmileyStateFromAllMeals(withFeedback: Bool = false) {
        let snapshot = self.historicalService.getSnapshot(for: self.selectedDate)
        let synthesis = self.synthesisEngine.synthesize(
            meals: self.meals,
            highlightData: snapshot?.highlightData,
            reflectData: snapshot?.reflectData,
            appleSleepData: self.appleSleepData,
            yesterday: nil
        )

        if withFeedback {
            let hapticsEnabled = UserDefaults.standard.object(forKey: StorageKeys.hapticsEnabled) as? Bool ?? true
            if hapticsEnabled {
                let overall = synthesis.dimensions.overall
                SensoryService.shared
                    .playNudge(style: overall < SynthesisThresholds.overallThoughtful ? .heavy : .light)
            }
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            self.smileyState = synthesis.smileySuggestion
        }
    }

    // MARK: - Day Reset

    /// Resets the day's progress (at midnight or via manual reset).
    func resetDay() {
        self.historicalService.archiveCurrentDay(
            meals: self.meals,
            state: self.smileyState,
            date: self.lastResetDate
        )

        let carried = self.historicalService.incompleteTodosForCarryOver(from: self.lastResetDate)
        if !carried.isEmpty {
            let existing = self.historicalService.getSnapshot(for: Date())?.highlightData
            let merged = HighlightData(
                sleepQuality: existing?.sleepQuality,
                sleepNotes: existing?.sleepNotes,
                todos: carried + (existing?.todos.filter { $0.carriedOverCount == 0 } ?? []),
                morningThoughts: existing?.morningThoughts
            )
            self.historicalService.updateHighlightData(for: Date(), data: merged)
        }

        let startingState = self.historicalService.foodDebtStartingState(relativeTo: Date())
        withAnimation(.easeOut) {
            self.smileyState = startingState
            self.meals = []
        }

        self.currentInsight = nil
        self.currentBriefing = nil

        self.saveData()
    }

    /// Completely deletes all app data including meals, history, and resets to factory state.
    /// This is a destructive operation and cannot be undone.
    func deleteAllData() {
        withAnimation(.easeOut) {
            self.smileyState = .neutral
            self.meals = []
            self.lastResetDate = Date()
        }

        self.historicalService.clearAllData()
        self.persistenceService.deleteAll()

        for key in StorageKeys.allKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        NotificationManager.shared.cancelAllNotifications()
    }
}
