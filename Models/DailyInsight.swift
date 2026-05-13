import Foundation

/// The single source of truth for a day's AI-generated wellbeing insight.
/// Replaces `LegacyDailyInsight`, `DailyBriefing`, and `EnrichedDailyInsight`.
/// All producers must generate this type; all consumers must read this type.
struct DailyInsight: Codable, Identifiable, Equatable {
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

    // MARK: - Computed

    var hasCorrelations: Bool { !self.correlationCards.isEmpty }

    var topCorrelation: CorrelationCard? {
        self.correlationCards.max(by: { $0.confidence < $1.confidence })
    }

    // MARK: - Mutations

    mutating func markAsViewed() {
        self.isViewed = true
    }
}
