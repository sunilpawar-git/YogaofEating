import Foundation

/// Protocol providing read-only data for module card bodies.
/// Decouples card views from MainViewModel, allowing testability and SOLID compliance.
@MainActor
protocol ModuleCardDataSource: AnyObject {
    // MARK: - Reflect Data

    var cardIntention: String? { get }
    var cardEnergyLevel: Int? { get }
    var cardSleepQuality: SleepQuality? { get }
    var shouldShowSetIntentionPrompt: Bool { get }

    // MARK: - Energise Data

    var cardMeals: [Meal] { get }
    var shouldShowLogMealPrompt: Bool { get }

    // MARK: - Laser Data

    var cardMorningTodos: [MindCheckEntry] { get }
    var cardFocusRating: Int? { get }

    // MARK: - Highlight Data

    var cardFeeling: ReflectionFeeling? { get }
    var cardInsightText: String? { get }
    var shouldShowEndOfDayPrompt: Bool { get }

    // MARK: - Actions

    func triggerSetIntention()
    func triggerLogMeal()
    func triggerEndOfDay()
}
