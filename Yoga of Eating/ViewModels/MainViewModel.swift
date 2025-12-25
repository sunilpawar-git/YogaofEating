import Foundation
import SwiftUI
import Combine

/// Central state manager for the Yoga of Eating app.
/// Strictly follows MVVM and handles interaction between View and Logic.
@MainActor
class MainViewModel: ObservableObject {
    
    @Published private(set) var smileyState: SmileyState = .neutral
    @Published private(set) var meals: [Meal] = []
    
    // Track the last reset date to detect when a new day starts
    private var lastResetDate: Date = Date()
    
    private let logicService: MealLogicProvider
    
    init(logicService: MealLogicProvider = MealLogicService()) {
        self.logicService = logicService
        setupResetMonitoring()
    }
    
    /// Periodically checks if the day has changed to reset the slate.
    private func setupResetMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndResetIfNewDay()
            }
        }
    }
    
    private func checkAndResetIfNewDay() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastResetDate) {
            resetDay()
            lastResetDate = Date()
        }
    }
    
    /// Adds a new empty meal entry. Triggered by tapping the Smiley.
    func createNewMeal() {
        checkAndResetIfNewDay()
        let newMeal = Meal()
        withAnimation(.spring()) {
            meals.append(newMeal)
        }
    }
    
    /// Updates an existing meal's description and recalculates health.
    func updateMeal(_ mealId: UUID, description: String) {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }
        
        let healthScore = logicService.calculateHealthScore(for: description)
        meals[index].description = description
        meals[index].healthScore = healthScore
        
        // Update Smiley state based on the CUMULATIVE health of the day
        // For simplicity, we'll take the average health score or the latest impact
        updateSmileyState(with: healthScore)
    }
    
    private func updateSmileyState(with healthScore: Double) {
        let nextState = logicService.calculateNextState(from: smileyState, healthScore: healthScore)
        
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
            smileyState = .neutral
            meals = []
        }
    }
}
