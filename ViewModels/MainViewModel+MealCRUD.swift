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

    /// Updates an existing meal's description and recalculates health.
    /// Legacy method for backward compatibility - converts to items array.
    func updateMeal(_ mealId: UUID, description: String) {
        self.updateMealItems(mealId, items: description.isEmpty ? [] : [description])
    }

    /// Updates an existing meal's items and recalculates health.
    func updateMealItems(_ mealId: UUID, items: [String], withFeedback: Bool = false) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        let contentChanged = Self.contentMeaningfullyChanged(old: self.meals[index].items, new: items)

        guard contentChanged else {
            crudLogger.debug("Skipping update - content unchanged after normalization")
            return
        }

        let healthScore = self.logicService.calculateHealthScore(for: items)
        self.meals[index].items = items
        self.meals[index].healthScore = healthScore
        self.meals[index].isAIAnalyzed = false

        self.saveData()
        crudLogger.debug("Local healthScore set to \(healthScore, privacy: .public)")

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
            items: items,
            in: self.makeAnalysisContext(mealId: mealId)
        )
    }

    /// Updates meal items locally WITHOUT triggering AI analysis.
    /// Use this for real-time updates during typing to provide immediate local feedback.
    /// AI analysis should be triggered separately via explicit user action (Done button, focus loss).
    func updateMealItemsLocalOnly(_ mealId: UUID, items: [String]) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        let contentChanged = Self.contentMeaningfullyChanged(old: self.meals[index].items, new: items)
        guard contentChanged else { return }

        let joinedDescription = items.joined(separator: ", ")
        if !joinedDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            switch InputValidator.validateMealDescription(joinedDescription) {
            case let .failure(error):
                self.lastValidationError = error
                self.showValidationErrorAlert = true
                return
            case .success:
                break
            }
        }

        self.meals[index].items = items

        if !self.meals[index].isAIAnalyzed {
            let healthScore = self.logicService.calculateHealthScore(for: items)
            self.meals[index].healthScore = healthScore
            crudLogger.debug("Local-only update: healthScore set to \(healthScore, privacy: .public)")
        } else {
            self.meals[index].isAIAnalyzed = false
            crudLogger.debug("Local-only update: items changed, AI score invalidated")
        }

        self.saveData()
    }

    /// Explicitly triggers AI analysis for a meal.
    /// Call this when user performs a "done" action (focus loss, Done button, Return key).
    func triggerAIAnalysisForMeal(_ mealId: UUID) async {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        self.meals[index].isAIAnalyzed = false
        self.saveData()

        let items = self.meals[index].items
        await self.performDeepAnalysis(for: mealId, items: items)
    }

    /// Updates meal type and items together.
    /// Called on "done" actions (focus loss, Done button, Return key) - always triggers AI analysis
    /// if the meal hasn't been AI-analyzed yet.
    func updateMeal(_ mealId: UUID, mealType: MealType, items: [String], withFeedback: Bool = false) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        let contentChanged = Self.contentMeaningfullyChanged(old: self.meals[index].items, new: items)
        let mealTypeChanged = self.meals[index].mealType != mealType
        let needsAIAnalysis = !self.meals[index].isAIAnalyzed && !items.isEmpty

        if mealTypeChanged {
            self.meals[index].mealType = mealType
        }

        if contentChanged {
            let healthScore = self.logicService.calculateHealthScore(for: items)
            self.meals[index].items = items
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
                items: items,
                in: self.makeAnalysisContext(mealId: mealId)
            )
        } else if mealTypeChanged {
            self.saveData()
        } else if needsAIAnalysis {
            crudLogger.debug("Triggering AI analysis for meal updated locally")
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
