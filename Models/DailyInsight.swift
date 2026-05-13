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

    // MARK: - Phase 2 bridge: converts DailyBriefing to unified insight.

    // Removed in Phase 4 when currentBriefing is deleted from MainViewModel.
    init(briefing: DailyBriefing) {
        self.init(
            id: briefing.id,
            date: briefing.date,
            generatedAt: briefing.generatedAt,
            headline: briefing.headline,
            dimensions: WellbeingDimensions(
                physicalLoad: 0.5,
                emotionalTone: 0.5,
                cognitiveClarity: 0.5,
                behavioralMomentum: 0.5
            ),
            dominantInsight: briefing.nudge.reasoning.isEmpty
                ? briefing.topCorrelation?.observation ?? briefing.headline
                : briefing.nudge.reasoning,
            correlationCards: briefing.correlationCards,
            nudge: briefing.nudge,
            weeklyTrend: briefing.weeklyTrend,
            causalExplanation: briefing.nudge.reasoning,
            textSignals: [.neutral],
            confidence: briefing.topCorrelation?.confidence ?? 0.5,
            isViewed: briefing.isViewed
        )
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
