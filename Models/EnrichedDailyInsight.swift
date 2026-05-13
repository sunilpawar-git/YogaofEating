import Foundation

/// The unified insight output from `InsightLifecycleService`.
/// Combines the four-dimension model, correlation cards, causal narrative,
/// and text signals into a single canonical daily intelligence object.
/// `DailyInsight` and `DailyBriefing` remain readable from historical snapshots
/// for backward compatibility with pre-Phase-5 data.
struct EnrichedDailyInsight: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let generatedAt: Date
    let headline: String
    let dimensions: WellbeingDimensions
    let dominantInsight: String
    let correlationCards: [CorrelationCard]
    let nudge: ActionableNudge
    let weeklyTrend: WeeklyTrendSnippet?
    let causalExplanation: String
    let textSignals: [TextSignal]
    let confidence: Double
    var isViewed: Bool

    init(
        id: UUID = UUID(),
        date: Date,
        generatedAt: Date = Date(),
        headline: String,
        dimensions: WellbeingDimensions,
        dominantInsight: String,
        correlationCards: [CorrelationCard],
        nudge: ActionableNudge,
        weeklyTrend: WeeklyTrendSnippet? = nil,
        causalExplanation: String,
        textSignals: [TextSignal],
        confidence: Double,
        isViewed: Bool = false
    ) {
        self.id = id
        self.date = date
        self.generatedAt = generatedAt
        self.headline = headline
        self.dimensions = dimensions
        self.dominantInsight = dominantInsight
        self.correlationCards = correlationCards
        self.nudge = nudge
        self.weeklyTrend = weeklyTrend
        self.causalExplanation = causalExplanation
        self.textSignals = textSignals
        self.confidence = max(0, min(1, confidence))
        self.isViewed = isViewed
    }

    mutating func markAsViewed() {
        self.isViewed = true
    }
}
