import Foundation

/// Represents a snapshot of a single day's eating data for archival purposes.
/// Captures meals, smiley state, health metrics, and optional end-of-day reflection for historical tracking.
struct DailySmileySnapshot: Codable, Identifiable {
    // MARK: - Properties

    let id: UUID
    let date: Date // Normalized to midnight (start of day)
    let smileyState: SmileyState
    let meals: [Meal]
    let mealCount: Int
    let averageHealthScore: Double

    /// Optional end-of-day reflection about how eating affected the user.
    /// Added in Phase 1 - backward compatible with existing snapshots (defaults to nil).
    let reflection: DailyReflection?

    // MARK: - Initialization

    /// Creates a new daily snapshot with all properties including optional reflection.
    init(
        id: UUID,
        date: Date,
        smileyState: SmileyState,
        meals: [Meal],
        mealCount: Int,
        averageHealthScore: Double,
        reflection: DailyReflection? = nil
    ) {
        self.id = id
        self.date = Calendar(identifier: .gregorian).startOfDay(for: date) // Normalize to midnight
        self.smileyState = smileyState
        self.meals = meals
        self.mealCount = mealCount
        self.averageHealthScore = averageHealthScore
        self.reflection = reflection
    }

    // MARK: - Codable (Backward Compatible)

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case smileyState
        case meals
        case mealCount
        case averageHealthScore
        case reflection
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = try Calendar(identifier: .gregorian).startOfDay(
            for: container.decode(Date.self, forKey: .date)
        )
        self.smileyState = try container.decode(SmileyState.self, forKey: .smileyState)
        self.meals = try container.decode([Meal].self, forKey: .meals)
        self.mealCount = try container.decode(Int.self, forKey: .mealCount)
        self.averageHealthScore = try container.decode(Double.self, forKey: .averageHealthScore)
        // Backward compatibility: reflection may not exist in legacy data
        self.reflection = try container.decodeIfPresent(DailyReflection.self, forKey: .reflection)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.date, forKey: .date)
        try container.encode(self.smileyState, forKey: .smileyState)
        try container.encode(self.meals, forKey: .meals)
        try container.encode(self.mealCount, forKey: .mealCount)
        try container.encode(self.averageHealthScore, forKey: .averageHealthScore)
        try container.encodeIfPresent(self.reflection, forKey: .reflection)
    }

    // MARK: - Computed Properties

    /// Returns true if no meals were logged this day
    var isEmpty: Bool {
        self.meals.isEmpty
    }

    /// Returns the smiley state to display in the UI.
    /// For empty days, returns a neutral state for dimmed display.
    /// Always returns a valid state with guaranteed finite, positive scale.
    var displayState: SmileyState {
        if self.isEmpty {
            return SmileyState(scale: 1.0, mood: .neutral)
        }
        // Ensure the scale is valid before returning
        let validScale = self.smileyState.scale.isFinite && self.smileyState.scale > 0
            ? min(max(self.smileyState.scale, 0.1), 10.0)
            : 1.0
        return SmileyState(scale: validScale, mood: self.smileyState.mood)
    }
}
