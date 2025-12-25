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
    
    /// Adds or updates a meal for a specific type.
    func addMeal(description: String, type: MealType) {
        // Ensure we are on a fresh slate if the day changed while app was in background
        checkAndResetIfNewDay()
        
        let healthScore = logicService.calculateHealthScore(for: description)
        
        let newMeal = Meal(
            type: type,
            description: description,
            healthScore: healthScore
        )
        
        // Overwrite if meal for this type already exists for today
        if let index = meals.firstIndex(where: { $0.type == type }) {
            meals[index] = newMeal
        } else {
            meals.append(newMeal)
        }
        
        // Update Smiley state based on this meal
        let nextState = logicService.calculateNextState(from: smileyState, healthScore: healthScore)
        
        // Sensory Feedback
        SensoryService.shared.playNudge(style: healthScore < 0.4 ? .heavy : .light)
        SensoryService.shared.playSound(for: nextState.scale)
        
        // Smoothly update smiley state
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            self.smileyState = nextState
        }
    }
    
    /// Returns the current meal description for a specific type, if any.
    func mealDescription(for type: MealType) -> String {
        return meals.first(where: { $0.type == type })?.description ?? ""
    }
    
    /// Resets the day's progress (at midnight or via manual reset).
    func resetDay() {
        withAnimation(.easeOut) {
            smileyState = .neutral
            meals = []
        }
    }
}
