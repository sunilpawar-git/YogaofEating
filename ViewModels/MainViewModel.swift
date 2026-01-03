import Combine
import Foundation
import SwiftUI

/// Protocol for persistence operations to enable testing
@MainActor
protocol PersistenceServiceProtocol {
    func load() -> PersistenceService.AppData?
    func save(meals: [Meal], smileyState: SmileyState, lastResetDate: Date, historicalData: HistoricalData)
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
    let historicalService: any HistoricalDataServiceProtocol
    let healthProfileService: HealthProfileServiceProtocol

    init(
        healthProfileService: HealthProfileServiceProtocol? = nil,
        logicService: MealLogicProvider? = nil,
        persistenceService: PersistenceServiceProtocol? = nil,
        historicalService: (any HistoricalDataServiceProtocol)? = nil
    ) {
        let healthService = healthProfileService ?? HealthProfileService()
        self.healthProfileService = healthService
        self.logicService = logicService ?? AILogicService()
        self.persistenceService = persistenceService ?? PersistenceService.shared
        self.historicalService = historicalService ?? HistoricalDataService()

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

        // Local synchronous update for immediate feedback
        let healthScore = self.logicService.calculateHealthScore(for: items)
        self.meals[index].items = items
        self.meals[index].healthScore = healthScore
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

        // Trigger async AI analysis for refined scoring
        Task {
            await self.performDeepAnalysis(for: mealId, items: items)
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
            let hapticsEnabled = UserDefaults.standard.object(forKey: "haptics_enabled") as? Bool ?? true

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
}
