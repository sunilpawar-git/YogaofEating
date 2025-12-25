import Combine
import Foundation
import SwiftUI

/// Central state manager for the Yoga of Eating app.
/// Strictly follows MVVM and handles interaction between View and Logic.
@MainActor
class MainViewModel: ObservableObject {
    @Published private(set) var smileyState: SmileyState = .neutral
    @Published private(set) var meals: [Meal] = []

    // Track the last reset date to detect when a new day starts
    @Published private var lastResetDate: Date = .init()

    private let logicService: MealLogicProvider

    init(logicService: MealLogicProvider? = nil) {
        self.logicService = logicService ?? MealLogicService()
        self.loadData()
        self.setupResetMonitoring()
    }

    /// Loads persisted data or starts fresh
    private func loadData() {
        if let data = PersistenceService.shared.load() {
            self.meals = data.meals
            self.smileyState = data.smileyState
            self.lastResetDate = data.lastResetDate

            // Still check if we need to reset for a new day since the last save
            self.checkAndResetIfNewDay()
        }
    }

    /// Saves current state
    private func saveData() {
        PersistenceService.shared.save(
            meals: self.meals,
            smileyState: self.smileyState,
            lastResetDate: self.lastResetDate
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
    func updateMealItems(_ mealId: UUID, items: [String]) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        let healthScore = self.logicService.calculateHealthScore(for: items)
        self.meals[index].items = items
        self.meals[index].healthScore = healthScore

        // Update Smiley state based on the CUMULATIVE health of the day
        self.updateSmileyState(with: healthScore)
        self.saveData()
    }

    /// Updates meal type and items together.
    func updateMeal(_ mealId: UUID, mealType: MealType, items: [String]) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        let healthScore = self.logicService.calculateHealthScore(for: items)
        self.meals[index].mealType = mealType
        self.meals[index].items = items
        self.meals[index].healthScore = healthScore

        self.updateSmileyState(with: healthScore)
        self.saveData()
    }

    /// Deletes a meal entry and recalculates smiley state.
    func deleteMeal(_ mealId: UUID) {
        withAnimation(.spring()) {
            self.meals.removeAll { $0.id == mealId }
        }

        // Recalculate smiley state based on remaining meals
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

    private func updateSmileyState(with healthScore: Double) {
        let nextState = self.logicService.calculateNextState(from: self.smileyState, healthScore: healthScore)

        // Sensory Feedback
        SensoryService.shared.playNudge(style: healthScore < 0.4 ? .heavy : .light)
        SensoryService.shared.playSound(for: nextState.scale)

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            self.smileyState = nextState
        }
    }

    /// Resets the day's progress (at midnight or via manual reset).
    func resetDay() {
        withAnimation(.easeOut) {
            self.smileyState = .neutral
            self.meals = []
        }
        self.saveData()
    }
}
