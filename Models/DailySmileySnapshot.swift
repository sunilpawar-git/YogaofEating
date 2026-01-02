import Foundation

/// Represents a snapshot of a single day's eating data for archival purposes.
/// Captures meals, smiley state, and health metrics for historical tracking.
struct DailySmileySnapshot: Codable, Identifiable {
    // MARK: - Properties

    let id: UUID
    let date: Date // Normalized to midnight (start of day)
    let smileyState: SmileyState
    let meals: [Meal]
    let mealCount: Int
    let averageHealthScore: Double

    // MARK: - Initialization

    init(
        id: UUID,
        date: Date,
        smileyState: SmileyState,
        meals: [Meal],
        mealCount: Int,
        averageHealthScore: Double
    ) {
        self.id = id
        self.date = Calendar(identifier: .gregorian).startOfDay(for: date) // Normalize to midnight
        self.smileyState = smileyState
        self.meals = meals
        self.mealCount = mealCount
        self.averageHealthScore = averageHealthScore
    }

    // MARK: - Computed Properties

    /// Returns true if no meals were logged this day
    var isEmpty: Bool {
        self.meals.isEmpty
    }

    /// Returns the smiley state to display in the UI.
    /// For empty days, returns a neutral state for dimmed display.
    var displayState: SmileyState {
        if self.isEmpty {
            SmileyState(scale: 1.0, mood: .neutral)
        } else {
            self.smileyState
        }
    }
}
