import Foundation

/// Conforms MainViewModel to ModuleCardDataSource, exposing read-only
/// data for the module card views without leaking internal state.
extension MainViewModel: ModuleCardDataSource {
    // MARK: - Reflect

    var cardIntention: String? { self.todaysIntention }
    var cardEnergyLevel: Int? { self.todaysEnergyLevel }
    var cardSleepQuality: SleepQuality? { self.todaysSleepQuality }

    var shouldShowSetIntentionPrompt: Bool {
        self.todaysIntention == nil
    }

    // MARK: - Energise

    var cardMeals: [Meal] { self.meals }

    var shouldShowLogMealPrompt: Bool {
        self.meals.isEmpty
    }

    // MARK: - Laser

    var cardMorningTodos: [MindCheckEntry] {
        self.todaysMorningMindCheck?.filter { $0.category == .todo } ?? []
    }

    var cardFocusRating: Int? { self.todaysFocusRating }

    // MARK: - Highlight

    var cardFeeling: ReflectionFeeling? { self.todaysFeeling }
    var cardInsightText: String? { self.currentInsight?.insightText }

    var shouldShowEndOfDayPrompt: Bool {
        self.todaysFeeling == nil
    }

    // MARK: - Actions

    func triggerSetIntention() {
        self.showReflectSheet = true
    }

    func triggerLogMeal() {
        self.handleSmileyTap()
    }

    func triggerEndOfDay() {
        self.isEndOfDayFlow = true
        self.showEveningMindCheckSheet = true
    }
}
