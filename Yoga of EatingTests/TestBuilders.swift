import Foundation
@testable import Yoga_of_Eating

// MARK: - MealBuilder

/// Fluent builder for `Meal` test fixtures.
/// Eliminates boilerplate `Meal(id: UUID(), items: ..., healthScore: ...)` across test files.
/// Builders are data factories only — mock behaviour lives in Mocks.swift.
final class MealBuilder {
    private var id = UUID()
    private var timestamp = Date()
    private var mealType = MealType.lunch
    private var items: [String] = ["test meal"]
    private var healthScore: Double = 0.5
    private var isAIAnalyzed = false
    private var aiInsight: String?

    @discardableResult
    func withID(_ id: UUID) -> Self {
        self.id = id
        return self
    }

    @discardableResult
    func withTimestamp(_ timestamp: Date) -> Self {
        self.timestamp = timestamp
        return self
    }

    @discardableResult
    func withMealType(_ type: MealType) -> Self {
        self.mealType = type
        return self
    }

    @discardableResult
    func withItems(_ items: [String]) -> Self {
        self.items = items
        return self
    }

    @discardableResult
    func withScore(_ score: Double) -> Self {
        self.healthScore = score
        return self
    }

    @discardableResult
    func analyzed() -> Self {
        self.isAIAnalyzed = true
        return self
    }

    @discardableResult
    func withInsight(_ insight: String) -> Self {
        self.aiInsight = insight
        return self
    }

    func build() -> Meal {
        Meal(
            id: self.id,
            timestamp: self.timestamp,
            mealType: self.mealType,
            items: self.items,
            healthScore: self.healthScore,
            isAIAnalyzed: self.isAIAnalyzed,
            aiInsight: self.aiInsight
        )
    }
}

// MARK: - DailySmileySnapshotBuilder

/// Fluent builder for `DailySmileySnapshot` test fixtures.
/// Auto-computes `mealCount` and `averageHealthScore` from the meals array.
final class DailySmileySnapshotBuilder {
    private var id = UUID()
    private var date = Date()
    private var smileyState = SmileyState.neutral
    private var meals: [Meal] = []
    private var reflection: DailyReflection?
    private var morningMindCheck: [MindCheckEntry]?
    private var eveningMindCheck: [MindCheckEntry]?
    private var highlightData: HighlightData?
    private var reflectData: ReflectData?
    private var briefing: DailyBriefing?
    private var insight: DailyInsight?
    private var wellbeingDimensions: WellbeingDimensions?
    private var textSignals: [TextSignal]?
    private var enrichedInsight: EnrichedDailyInsight?

    @discardableResult
    func withID(_ id: UUID) -> Self {
        self.id = id
        return self
    }

    @discardableResult
    func withDate(_ date: Date) -> Self {
        self.date = date
        return self
    }

    /// Sets the snapshot date to N days before today (midnight-normalised).
    @discardableResult
    func daysAgo(_ days: Int) -> Self {
        self.date = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return self
    }

    @discardableResult
    func withSmileyState(_ state: SmileyState) -> Self {
        self.smileyState = state
        return self
    }

    @discardableResult
    func withMeals(_ meals: [Meal]) -> Self {
        self.meals = meals
        return self
    }

    @discardableResult
    func withInsight(_ insight: DailyInsight) -> Self {
        self.insight = insight
        return self
    }

    @discardableResult
    func withBriefing(_ briefing: DailyBriefing) -> Self {
        self.briefing = briefing
        return self
    }

    @discardableResult
    func withMorningMindCheck(_ entries: [MindCheckEntry]) -> Self {
        self.morningMindCheck = entries
        return self
    }

    @discardableResult
    func withEveningMindCheck(_ entries: [MindCheckEntry]) -> Self {
        self.eveningMindCheck = entries
        return self
    }

    @discardableResult
    func withReflection(_ reflection: DailyReflection) -> Self {
        self.reflection = reflection
        return self
    }

    @discardableResult
    func withHighlightData(_ data: HighlightData) -> Self {
        self.highlightData = data
        return self
    }

    @discardableResult
    func withReflectData(_ data: ReflectData) -> Self {
        self.reflectData = data
        return self
    }

    @discardableResult
    func withEnrichedInsight(_ insight: EnrichedDailyInsight) -> Self {
        self.enrichedInsight = insight
        return self
    }

    @discardableResult
    func withWellbeingDimensions(_ dimensions: WellbeingDimensions) -> Self {
        self.wellbeingDimensions = dimensions
        return self
    }

    @discardableResult
    func withTextSignals(_ signals: [TextSignal]) -> Self {
        self.textSignals = signals
        return self
    }

    func build() -> DailySmileySnapshot {
        let mealCount = self.meals.count
        let avgScore = self.meals.isEmpty
            ? 0.5
            : self.meals.map(\.healthScore).reduce(0.0, +) / Double(mealCount)

        return DailySmileySnapshot(
            id: self.id,
            date: self.date,
            smileyState: self.smileyState,
            meals: self.meals,
            mealCount: mealCount,
            averageHealthScore: avgScore,
            reflection: self.reflection,
            morningMindCheck: self.morningMindCheck,
            eveningMindCheck: self.eveningMindCheck,
            highlightData: self.highlightData,
            reflectData: self.reflectData,
            briefing: self.briefing,
            insight: self.insight,
            wellbeingDimensions: self.wellbeingDimensions,
            textSignals: self.textSignals,
            enrichedInsight: self.enrichedInsight
        )
    }
}

// MARK: - MindCheckEntryBuilder

/// Fluent builder for `MindCheckEntry` test fixtures.
final class MindCheckEntryBuilder {
    private var id = UUID()
    private var category: MindCheckCategory = .todo
    private var text = "Test task"
    private var timestamp = Date()
    private var context: MindCheckContext = .morning
    private var isAccomplished: Bool?
    private var carriedOverCount = 0

    @discardableResult
    func withID(_ id: UUID) -> Self {
        self.id = id
        return self
    }

    @discardableResult
    func withCategory(_ category: MindCheckCategory) -> Self {
        self.category = category
        return self
    }

    @discardableResult
    func withText(_ text: String) -> Self {
        self.text = text
        return self
    }

    @discardableResult
    func withContext(_ context: MindCheckContext) -> Self {
        self.context = context
        return self
    }

    @discardableResult
    func accomplished() -> Self {
        self.isAccomplished = true
        return self
    }

    @discardableResult
    func withCarriedOverCount(_ count: Int) -> Self {
        self.carriedOverCount = count
        return self
    }

    func build() -> MindCheckEntry {
        MindCheckEntry(
            id: self.id,
            category: self.category,
            text: self.text,
            timestamp: self.timestamp,
            context: self.context,
            isAccomplished: self.isAccomplished,
            carriedOverCount: self.carriedOverCount
        )
    }
}

// MARK: - DailyInsightBuilder

/// Fluent builder for `DailyInsight` test fixtures.
final class DailyInsightBuilder {
    private var id = UUID()
    private var date = Date()
    private var insightText = "Your eating patterns look balanced."
    private var insightType: InsightType = .encouragement
    private var confidence: Double = 0.8
    private var isViewed = false
    private var references: [InsightReference] = []

    @discardableResult
    func withID(_ id: UUID) -> Self {
        self.id = id
        return self
    }

    @discardableResult
    func withDate(_ date: Date) -> Self {
        self.date = date
        return self
    }

    @discardableResult
    func withText(_ text: String) -> Self {
        self.insightText = text
        return self
    }

    @discardableResult
    func withType(_ type: InsightType) -> Self {
        self.insightType = type
        return self
    }

    @discardableResult
    func withConfidence(_ confidence: Double) -> Self {
        self.confidence = confidence
        return self
    }

    @discardableResult
    func viewed() -> Self {
        self.isViewed = true
        return self
    }

    func build() -> DailyInsight {
        DailyInsight(
            id: self.id,
            date: self.date,
            insightText: self.insightText,
            insightType: self.insightType,
            confidence: self.confidence,
            isViewed: self.isViewed,
            references: self.references
        )
    }
}

// MARK: - HealthProfileBuilder

/// Fluent builder for `UserHealthProfile` test fixtures.
final class HealthProfileBuilder {
    private var age = 28
    private var bmi = 22.0
    private var bmr = 1600.0
    private var tdee = 2100.0
    private var riskLevel: HealthRiskLevel = .low
    private var sensitivityMultiplier = 1.0

    @discardableResult
    func withAge(_ age: Int) -> Self {
        self.age = age
        return self
    }

    @discardableResult
    func withBMI(_ bmi: Double) -> Self {
        self.bmi = bmi
        return self
    }

    @discardableResult
    func withBMR(_ bmr: Double) -> Self {
        self.bmr = bmr
        return self
    }

    @discardableResult
    func withTDEE(_ tdee: Double) -> Self {
        self.tdee = tdee
        return self
    }

    @discardableResult
    func withRiskLevel(_ level: HealthRiskLevel) -> Self {
        self.riskLevel = level
        return self
    }

    @discardableResult
    func withSensitivityMultiplier(_ multiplier: Double) -> Self {
        self.sensitivityMultiplier = multiplier
        return self
    }

    func build() -> UserHealthProfile {
        UserHealthProfile(
            age: self.age,
            bmi: self.bmi,
            bmiCategory: BMICategory.from(bmi: self.bmi),
            bmr: self.bmr,
            tdee: self.tdee,
            riskLevel: self.riskLevel,
            sensitivityMultiplier: self.sensitivityMultiplier
        )
    }
}
