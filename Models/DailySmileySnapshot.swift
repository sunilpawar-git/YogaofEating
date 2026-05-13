import Foundation

/// Represents a snapshot of a single day's eating data for archival purposes.
struct DailySmileySnapshot: Codable, Identifiable {
    // MARK: - Core Properties

    let id: UUID
    let date: Date
    let smileyState: SmileyState
    let meals: [Meal]
    let mealCount: Int
    let averageHealthScore: Double
    let reflection: DailyReflection?
    let morningMindCheck: [MindCheckEntry]?
    let eveningMindCheck: [MindCheckEntry]?
    let highlightData: HighlightData?
    let reflectData: ReflectData?
    let totalCalories: Int?
    let hasCompleteCalorieData: Bool
    let wellbeingDimensions: WellbeingDimensions?
    let textSignals: [TextSignal]?

    /// Single SSOT insight for this day. Replaces the legacy `briefing`, `insight`,
    /// and `enrichedInsight` fields. Migration decoder reads those old keys on first load.
    let insight: DailyInsight?

    // MARK: - Initialization

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
        totalCalories: Int? = nil,
        hasCompleteCalorieData: Bool = false,
        wellbeingDimensions: WellbeingDimensions? = nil,
        textSignals: [TextSignal]? = nil,
        insight: DailyInsight? = nil
    ) {
        self.id = id
        self.date = Calendar(identifier: .gregorian).startOfDay(for: date)
        self.smileyState = smileyState
        self.meals = meals
        self.mealCount = mealCount
        self.averageHealthScore = averageHealthScore
        self.reflection = reflection
        self.morningMindCheck = morningMindCheck
        self.eveningMindCheck = eveningMindCheck
        self.highlightData = highlightData
        self.reflectData = reflectData
        self.totalCalories = totalCalories
        self.hasCompleteCalorieData = hasCompleteCalorieData
        self.wellbeingDimensions = wellbeingDimensions
        self.textSignals = textSignals
        self.insight = insight
    }

    // MARK: - Codable (Backward Compatible — Phase 2 migration)

    enum CodingKeys: String, CodingKey {
        case id, date, smileyState, meals, mealCount, averageHealthScore
        case reflection, morningMindCheck, eveningMindCheck
        case highlightData, reflectData
        case totalCalories, hasCompleteCalorieData
        case wellbeingDimensions, textSignals
        // Current storage key for unified DailyInsight
        case insight
        // Migration-only keys (read-only; written by pre-Phase-3/5 builds)
        case enrichedInsight
        case briefing
    }

    /// Minimal decoder for the legacy `DailyBriefing` format stored under the `briefing` key.
    /// Only decodes fields that were present in old builds; missing fields get safe defaults.
    private struct LegacyBriefingPayload: Decodable {
        let id: UUID
        let date: Date
        let generatedAt: Date
        let headline: String
        let correlationCards: [CorrelationCard]
        let nudge: ActionableNudge
        let isViewed: Bool

        func asDailyInsight() -> DailyInsight {
            DailyInsight(
                id: self.id,
                date: self.date,
                generatedAt: self.generatedAt,
                headline: self.headline,
                dimensions: WellbeingDimensions(
                    physicalLoad: 0.5,
                    emotionalTone: 0.5,
                    cognitiveClarity: 0.5,
                    behavioralMomentum: 0.5
                ),
                dominantInsight: "",
                correlationCards: self.correlationCards,
                nudge: self.nudge,
                causalExplanation: "",
                textSignals: [],
                confidence: 0.5,
                isViewed: self.isViewed
            )
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.date = try Calendar(identifier: .gregorian).startOfDay(
            for: c.decode(Date.self, forKey: .date)
        )
        self.smileyState = try c.decode(SmileyState.self, forKey: .smileyState)
        self.meals = try c.decode([Meal].self, forKey: .meals)
        self.mealCount = try c.decode(Int.self, forKey: .mealCount)
        self.averageHealthScore = try c.decode(Double.self, forKey: .averageHealthScore)
        self.reflection = try c.decodeIfPresent(DailyReflection.self, forKey: .reflection)
        self.morningMindCheck = try c.decodeIfPresent([MindCheckEntry].self, forKey: .morningMindCheck)
        self.eveningMindCheck = try c.decodeIfPresent([MindCheckEntry].self, forKey: .eveningMindCheck)
        self.highlightData = try c.decodeIfPresent(HighlightData.self, forKey: .highlightData)
        self.reflectData = try c.decodeIfPresent(ReflectData.self, forKey: .reflectData)
        self.totalCalories = try c.decodeIfPresent(Int.self, forKey: .totalCalories)
        self.hasCompleteCalorieData = try c.decodeIfPresent(Bool.self, forKey: .hasCompleteCalorieData) ?? false
        self.wellbeingDimensions = try c.decodeIfPresent(WellbeingDimensions.self, forKey: .wellbeingDimensions)
        self.textSignals = try c.decodeIfPresent([TextSignal].self, forKey: .textSignals)

        // Migration priority: new `insight` → `enrichedInsight` → converted `briefing`
        if let unified = try? c.decodeIfPresent(DailyInsight.self, forKey: .insight) {
            self.insight = unified
        } else if let enriched = try? c.decodeIfPresent(DailyInsight.self, forKey: .enrichedInsight) {
            self.insight = enriched
        } else if let legacy = try? c.decodeIfPresent(LegacyBriefingPayload.self, forKey: .briefing) {
            self.insight = legacy.asDailyInsight()
        } else {
            self.insight = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(self.id, forKey: .id)
        try c.encode(self.date, forKey: .date)
        try c.encode(self.smileyState, forKey: .smileyState)
        try c.encode(self.meals, forKey: .meals)
        try c.encode(self.mealCount, forKey: .mealCount)
        try c.encode(self.averageHealthScore, forKey: .averageHealthScore)
        try c.encodeIfPresent(self.reflection, forKey: .reflection)
        try c.encodeIfPresent(self.morningMindCheck, forKey: .morningMindCheck)
        try c.encodeIfPresent(self.eveningMindCheck, forKey: .eveningMindCheck)
        try c.encodeIfPresent(self.highlightData, forKey: .highlightData)
        try c.encodeIfPresent(self.reflectData, forKey: .reflectData)
        try c.encodeIfPresent(self.totalCalories, forKey: .totalCalories)
        try c.encode(self.hasCompleteCalorieData, forKey: .hasCompleteCalorieData)
        try c.encodeIfPresent(self.wellbeingDimensions, forKey: .wellbeingDimensions)
        try c.encodeIfPresent(self.textSignals, forKey: .textSignals)
        try c.encodeIfPresent(self.insight, forKey: .insight)
        // Do NOT write `enrichedInsight` or `briefing` — legacy keys are read-only migration paths
    }

    // MARK: - Computed Properties

    var isEmpty: Bool { self.meals.isEmpty }

    var displayState: SmileyState {
        if self.isEmpty { return SmileyState(scale: 1.0, mood: .neutral) }
        let validScale = self.smileyState.scale.isFinite && self.smileyState.scale > 0
            ? min(max(self.smileyState.scale, 0.1), 10.0)
            : 1.0
        return SmileyState(scale: validScale, mood: self.smileyState.mood)
    }

    var hasMorningMindCheck: Bool { !(self.morningMindCheck ?? []).isEmpty }
    var hasEveningMindCheck: Bool { !(self.eveningMindCheck ?? []).isEmpty }
    var hasInsight: Bool { self.insight != nil }
}
