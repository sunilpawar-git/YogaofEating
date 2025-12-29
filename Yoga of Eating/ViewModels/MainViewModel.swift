import Combine
import Foundation
import SwiftUI

/// Protocol for persistence operations to enable testing
protocol PersistenceServiceProtocol {
    func load() -> PersistenceService.AppData?
    func save(meals: [Meal], smileyState: SmileyState, lastResetDate: Date)
}

/// Central state manager for the Yoga of Eating app.
/// Strictly follows MVVM and handles interaction between View and Logic.
@MainActor
class MainViewModel: ObservableObject {
    @Published var smileyState: SmileyState = .neutral
    @Published var meals: [Meal] = []
    @Published var lastResetDate: Date = .init()

    let logicService: MealLogicProvider
    let persistenceService: PersistenceServiceProtocol

    init(logicService: MealLogicProvider? = nil, persistenceService: PersistenceServiceProtocol? = nil) {
        self.logicService = logicService ?? AILogicService()
        self.persistenceService = persistenceService ?? PersistenceService.shared
        print("🚀 MainViewModel initialized with \(type(of: self.logicService))")
        if self.logicService is AILogicService {
            print("✅ AI Integration is ACTIVE - Gemini will analyze meals!")
        } else {
            print("⚠️ Using local logic service (no AI)")
        }
        self.loadData()
        self.setupResetMonitoring()
    }

    /// Loads persisted data or starts fresh
    func loadData() {
        if let data = self.persistenceService.load() {
            self.meals = data.meals
            self.smileyState = data.smileyState
            self.lastResetDate = data.lastResetDate

            // Still check if we need to reset for a new day since the last save
            self.checkAndResetIfNewDay()
        }
    }

    /// Saves current state
    func saveData() {
        self.persistenceService.save(
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
        print("➕ Creating new meal - ID: \(newMeal.id), Type: \(newMeal.mealType.rawValue)")
        withAnimation(.spring()) {
            self.meals.append(newMeal)
        }
        self.saveData()
        print("📋 Total meals: \(self.meals.count)")
    }

    /// Updates an existing meal's description and recalculates health.
    /// Legacy method for backward compatibility - converts to items array.
    func updateMeal(_ mealId: UUID, description: String) {
        self.updateMealItems(mealId, items: description.isEmpty ? [] : [description])
    }

    /// Updates an existing meal's items and recalculates health.
    func updateMealItems(_ mealId: UUID, items: [String]) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        let description = items.joined(separator: ", ")
        print("🍽️ Meal updated - ID: \(mealId), Items: \(description)")

        // Local synchronous update for immediate feedback
        let healthScore = self.logicService.calculateHealthScore(for: items)
        self.meals[index].items = items
        self.meals[index].healthScore = healthScore
        self.saveData()
        print("📝 Local healthScore set to: \(healthScore)")

        // Immediately update smiley state with current meal scores
        self.updateSmileyStateFromAllMeals()
        print(
            "😊 Smiley state updated immediately - Mood: \(self.smileyState.mood.rawValue), "
                + "Scale: \(self.smileyState.scale)"
        )

        // Trigger async AI analysis for refined scoring
        Task {
            await self.performDeepAnalysis(for: mealId, items: items)
        }
    }

    /// Updates meal type and items together.
    func updateMeal(_ mealId: UUID, mealType: MealType, items: [String]) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        let description = items.joined(separator: ", ")
        print("🍽️ Meal updated - ID: \(mealId), Type: \(mealType), Items: \(description)")

        // Local synchronous update
        let healthScore = self.logicService.calculateHealthScore(for: items)
        self.meals[index].mealType = mealType
        self.meals[index].items = items
        self.meals[index].healthScore = healthScore
        self.saveData()
        print("📝 Local healthScore set to: \(healthScore)")

        // Immediately update smiley state with current meal scores
        self.updateSmileyStateFromAllMeals()
        print(
            "😊 Smiley state updated immediately - Mood: \(self.smileyState.mood.rawValue), "
                + "Scale: \(self.smileyState.scale)"
        )

        // Trigger async AI analysis
        Task {
            await self.performDeepAnalysis(for: mealId, items: items)
        }
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

    func updateSmileyState(with healthScore: Double) {
        let nextState = self.logicService.calculateNextState(
            from: self.smileyState,
            healthScore: healthScore
        )
        print(
            "🔄 Updating smiley - HealthScore: \(healthScore), "
                + "Current mood: \(self.smileyState.mood.rawValue) -> New mood: \(nextState.mood.rawValue), "
                + "Scale: \(self.smileyState.scale) -> \(nextState.scale)"
        )

        // Sensory Feedback
        SensoryService.shared.playNudge(style: healthScore < 0.4 ? .heavy : .light)
        SensoryService.shared.playSound(for: nextState.scale)

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            self.smileyState = nextState
        }
    }

    /// Updates smiley state based on all current meals' health scores.
    private func updateSmileyStateFromAllMeals() {
        guard !self.meals.isEmpty else {
            print("📭 No meals found, setting smiley to neutral")
            withAnimation(.spring()) {
                self.smileyState = .neutral
            }
            return
        }

        // Calculate average health score from all meals
        let totalScore = self.meals.map(\.healthScore).reduce(0.0, +)
        let avgScore = totalScore / Double(self.meals.count)
        print(
            "📊 Calculating smiley from \(self.meals.count) meals - Average score: \(avgScore)"
        )

        self.updateSmileyState(with: avgScore)
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
