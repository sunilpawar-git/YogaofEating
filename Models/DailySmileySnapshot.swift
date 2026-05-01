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

    /// Optional morning mind check entries (todos, gratitude, thoughts).
    /// Added in Phase 2 - Mind Check feature.
    let morningMindCheck: [MindCheckEntry]?

    /// Optional evening mind check entries (accomplished, grateful for, let go).
    /// Added in Phase 2 - Mind Check feature.
    let eveningMindCheck: [MindCheckEntry]?

    /// Highlight tab data (sleep, todos, morning thoughts). Added in Tab Redesign.
    let highlightData: HighlightData?

    /// Reflect tab data (journal, feeling). Added in Tab Redesign.
    let reflectData: ReflectData?

    /// Morning briefing generated from yesterday's data. Added in Briefing Engine.
    let briefing: DailyBriefing?

    // MARK: - Initialization

    /// Creates a new daily snapshot with all properties including optional reflection and mind checks.
    init(
        id: UUID,
        date: Date,
        smileyState: SmileyState,
        meals: [Meal],
        mealCount: Int,
        averageHealthScore: Double,
        reflection: DailyReflection? = nil,
        morningMindCheck: [MindCheckEntry]? = nil,
        eveningMindCheck: [MindCheckEntry]? = nil,
        highlightData: HighlightData? = nil,
        reflectData: ReflectData? = nil,
        briefing: DailyBriefing? = nil
    ) {
        self.id = id
        self.date = Calendar(identifier: .gregorian).startOfDay(for: date) // Normalize to midnight
        self.smileyState = smileyState
        self.meals = meals
        self.mealCount = mealCount
        self.averageHealthScore = averageHealthScore
        self.reflection = reflection
        self.morningMindCheck = morningMindCheck
        self.eveningMindCheck = eveningMindCheck
        self.highlightData = highlightData
        self.reflectData = reflectData
        self.briefing = briefing
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
        case morningMindCheck
        case eveningMindCheck
        case highlightData
        case reflectData
        case briefing
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
        // Backward compatibility: optional fields may not exist in legacy data
        self.reflection = try container.decodeIfPresent(DailyReflection.self, forKey: .reflection)
        self.morningMindCheck = try container.decodeIfPresent([MindCheckEntry].self, forKey: .morningMindCheck)
        self.eveningMindCheck = try container.decodeIfPresent([MindCheckEntry].self, forKey: .eveningMindCheck)
        self.highlightData = try container.decodeIfPresent(HighlightData.self, forKey: .highlightData)
        self.reflectData = try container.decodeIfPresent(ReflectData.self, forKey: .reflectData)
        self.briefing = try container.decodeIfPresent(DailyBriefing.self, forKey: .briefing)
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
        try container.encodeIfPresent(self.morningMindCheck, forKey: .morningMindCheck)
        try container.encodeIfPresent(self.eveningMindCheck, forKey: .eveningMindCheck)
        try container.encodeIfPresent(self.highlightData, forKey: .highlightData)
        try container.encodeIfPresent(self.reflectData, forKey: .reflectData)
        try container.encodeIfPresent(self.briefing, forKey: .briefing)
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

    /// Returns true if morning mind check has been logged with at least one entry
    var hasMorningMindCheck: Bool {
        guard let entries = self.morningMindCheck else { return false }
        return !entries.isEmpty
    }

    /// Returns true if evening mind check has been logged with at least one entry
    var hasEveningMindCheck: Bool {
        guard let entries = self.eveningMindCheck else { return false }
        return !entries.isEmpty
    }

    /// Returns true if a morning briefing has been generated for this day
    var hasBriefing: Bool {
        self.briefing != nil
    }

    // MARK: - Factory Methods

    /// Creates a snapshot from current day's data.
    /// Automatically calculates mealCount and averageHealthScore from the meals array.
    /// - Parameters:
    ///   - date: The date for this snapshot
    ///   - smileyState: The smiley state at end of day
    ///   - meals: All meals logged for the day
    ///   - reflection: Optional end-of-day reflection
    ///   - morningMindCheck: Optional morning mind check entries
    ///   - eveningMindCheck: Optional evening mind check entries
    /// - Returns: A new DailySmileySnapshot with computed metrics
    static func create(
        date: Date,
        smileyState: SmileyState,
        meals: [Meal],
        reflection: DailyReflection? = nil,
        morningMindCheck: [MindCheckEntry]? = nil,
        eveningMindCheck: [MindCheckEntry]? = nil,
        highlightData: HighlightData? = nil,
        reflectData: ReflectData? = nil,
        briefing: DailyBriefing? = nil
    ) -> DailySmileySnapshot {
        let mealCount = meals.count
        let averageHealthScore = meals.isEmpty
            ? 0.5
            : meals.map(\.healthScore).reduce(0.0, +) / Double(meals.count)

        return DailySmileySnapshot(
            id: UUID(),
            date: date,
            smileyState: smileyState,
            meals: meals,
            mealCount: mealCount,
            averageHealthScore: averageHealthScore,
            reflection: reflection,
            morningMindCheck: morningMindCheck,
            eveningMindCheck: eveningMindCheck,
            highlightData: highlightData,
            reflectData: reflectData,
            briefing: briefing
        )
    }

    /// Creates a copy of this snapshot with updated mind check entries.
    /// Useful for adding mind check data to an existing snapshot.
    /// - Parameters:
    ///   - morningMindCheck: New morning mind check entries (nil to keep existing)
    ///   - eveningMindCheck: New evening mind check entries (nil to keep existing)
    /// - Returns: A new snapshot with updated mind check data
    func withMindChecks(
        morningMindCheck: [MindCheckEntry]? = nil,
        eveningMindCheck: [MindCheckEntry]? = nil
    ) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: self.id,
            date: self.date,
            smileyState: self.smileyState,
            meals: self.meals,
            mealCount: self.mealCount,
            averageHealthScore: self.averageHealthScore,
            reflection: self.reflection,
            morningMindCheck: morningMindCheck ?? self.morningMindCheck,
            eveningMindCheck: eveningMindCheck ?? self.eveningMindCheck,
            highlightData: self.highlightData,
            reflectData: self.reflectData,
            briefing: self.briefing
        )
    }

    /// Creates a copy of this snapshot with updated reflection.
    /// - Parameter reflection: The new reflection data
    /// - Returns: A new snapshot with updated reflection
    func withReflection(_ reflection: DailyReflection) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: self.id,
            date: self.date,
            smileyState: self.smileyState,
            meals: self.meals,
            mealCount: self.mealCount,
            averageHealthScore: self.averageHealthScore,
            reflection: reflection,
            morningMindCheck: self.morningMindCheck,
            eveningMindCheck: self.eveningMindCheck,
            highlightData: self.highlightData,
            reflectData: self.reflectData,
            briefing: self.briefing
        )
    }

    /// Creates a copy with updated highlight data.
    func withHighlightData(_ highlightData: HighlightData) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: self.id,
            date: self.date,
            smileyState: self.smileyState,
            meals: self.meals,
            mealCount: self.mealCount,
            averageHealthScore: self.averageHealthScore,
            reflection: self.reflection,
            morningMindCheck: self.morningMindCheck,
            eveningMindCheck: self.eveningMindCheck,
            highlightData: highlightData,
            reflectData: self.reflectData,
            briefing: self.briefing
        )
    }

    /// Creates a copy with updated reflect data.
    func withReflectData(_ reflectData: ReflectData) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: self.id,
            date: self.date,
            smileyState: self.smileyState,
            meals: self.meals,
            mealCount: self.mealCount,
            averageHealthScore: self.averageHealthScore,
            reflection: self.reflection,
            morningMindCheck: self.morningMindCheck,
            eveningMindCheck: self.eveningMindCheck,
            highlightData: self.highlightData,
            reflectData: reflectData,
            briefing: self.briefing
        )
    }

    /// Creates a copy with updated briefing data.
    func withBriefing(_ briefing: DailyBriefing) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: self.id,
            date: self.date,
            smileyState: self.smileyState,
            meals: self.meals,
            mealCount: self.mealCount,
            averageHealthScore: self.averageHealthScore,
            reflection: self.reflection,
            morningMindCheck: self.morningMindCheck,
            eveningMindCheck: self.eveningMindCheck,
            highlightData: self.highlightData,
            reflectData: self.reflectData,
            briefing: briefing
        )
    }
}
