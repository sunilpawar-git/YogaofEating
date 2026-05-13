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
    let briefing: DailyBriefing?
    let insight: DailyInsight?
    let totalCalories: Int?
    let hasCompleteCalorieData: Bool

    /// Four-dimension holistic wellbeing model. Added in Synthesis Layer phase.
    let wellbeingDimensions: WellbeingDimensions?

    /// Structured emotional signals extracted from free text. Added in Synthesis Layer phase.
    let textSignals: [TextSignal]?

    /// Unified enriched insight combining synthesis + correlations + causal narrative. Added in Phase 5.
    let enrichedInsight: EnrichedDailyInsight?

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
        briefing: DailyBriefing? = nil,
        insight: DailyInsight? = nil,
        totalCalories: Int? = nil,
        hasCompleteCalorieData: Bool = false,
        wellbeingDimensions: WellbeingDimensions? = nil,
        textSignals: [TextSignal]? = nil,
        enrichedInsight: EnrichedDailyInsight? = nil
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
        self.briefing = briefing
        self.insight = insight
        self.totalCalories = totalCalories
        self.hasCompleteCalorieData = hasCompleteCalorieData
        self.wellbeingDimensions = wellbeingDimensions
        self.textSignals = textSignals
        self.enrichedInsight = enrichedInsight
    }

    // MARK: - Codable (Backward Compatible)

    enum CodingKeys: String, CodingKey {
        case id, date, smileyState, meals, mealCount, averageHealthScore
        case reflection, morningMindCheck, eveningMindCheck
        case highlightData, reflectData, briefing, insight
        case totalCalories, hasCompleteCalorieData
        case wellbeingDimensions, textSignals, enrichedInsight
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
        self.briefing = try c.decodeIfPresent(DailyBriefing.self, forKey: .briefing)
        self.insight = try c.decodeIfPresent(DailyInsight.self, forKey: .insight)
        self.totalCalories = try c.decodeIfPresent(Int.self, forKey: .totalCalories)
        self.hasCompleteCalorieData = try c.decodeIfPresent(Bool.self, forKey: .hasCompleteCalorieData) ?? false
        self.wellbeingDimensions = try c.decodeIfPresent(WellbeingDimensions.self, forKey: .wellbeingDimensions)
        self.textSignals = try c.decodeIfPresent([TextSignal].self, forKey: .textSignals)
        self.enrichedInsight = try c.decodeIfPresent(EnrichedDailyInsight.self, forKey: .enrichedInsight)
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
        try c.encodeIfPresent(self.briefing, forKey: .briefing)
        try c.encodeIfPresent(self.insight, forKey: .insight)
        try c.encodeIfPresent(self.totalCalories, forKey: .totalCalories)
        try c.encode(self.hasCompleteCalorieData, forKey: .hasCompleteCalorieData)
        try c.encodeIfPresent(self.wellbeingDimensions, forKey: .wellbeingDimensions)
        try c.encodeIfPresent(self.textSignals, forKey: .textSignals)
        try c.encodeIfPresent(self.enrichedInsight, forKey: .enrichedInsight)
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
    var hasBriefing: Bool { self.briefing != nil }
    var hasInsight: Bool { self.insight != nil }
}
