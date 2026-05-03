import Foundation

/// Named thresholds for briefing correlation analysis (SSOT for PatternAnalyzer magic numbers).
enum BriefingThresholds {
    static let timingConsistencyStdDev: Double = 5.5
    static let scoreDifferenceSignificant: Double = 0.15
    static let minimumScoreDelta: Double = 0.1
    /// Minimum snapshots required before pattern detection runs.
    static let minimumDataPoints: Int = 3
    /// Confidence threshold for surfacing a detected pattern.
    static let confidenceThreshold: Double = 0.6
    /// Hour after which dinner is considered "late".
    static let lateDinnerHour: Int = 21
    /// Maximum insight references shown per card.
    static let maximumInsightReferences: Int = 3
}

/// Dispatches pattern analysis requests to `PatternAnalysisEngine`.
///
/// This class is intentionally thin — all computation lives in `PatternAnalysisEngine`
/// so that individual algorithms can be tested and evolved independently.
/// `PatternAnalyzer` is retained as the public API surface for backward compatibility
/// with `InsightGenerationService` and its tests.
class PatternAnalyzer {
    private let engine: PatternAnalysisEngine

    init(engine: PatternAnalysisEngine = PatternAnalysisEngine()) {
        self.engine = engine
    }

    // MARK: - Legacy Insight Pipeline

    /// Analyzes all available patterns from the given snapshots.
    /// Feeds the legacy `DailyInsight` text pipeline.
    func analyzePatterns(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        self.engine.analyzePatterns(from: snapshots)
    }

    // MARK: - Briefing Cards Pipeline

    /// Produces `CorrelationCard`s from all analyzers, sorted by confidence.
    /// Feeds the `DailyBriefing` cards pipeline.
    func generateCorrelationCards(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        self.engine.generateCorrelationCards(from: snapshots)
    }

    // MARK: - Individual Sub-Analyzer Forwarders

    // These delegate to the engine so that existing tests calling sub-analyzers
    // directly on PatternAnalyzer continue to work without modification.

    func analyzeFoodSleepCorrelation(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        self.engine.analyzeFoodSleepCorrelation(from: snapshots)
    }

    func analyzeTodoMoodCorrelation(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        self.engine.analyzeTodoMoodCorrelation(from: snapshots)
    }

    func analyzeGratitudePractice(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        self.engine.analyzeGratitudePractice(from: snapshots)
    }

    func analyzeFoodDebt(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        self.engine.analyzeFoodDebt(from: snapshots)
    }

    func analyzeFoodToFeeling(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        self.engine.analyzeFoodToFeeling(from: snapshots)
    }

    func analyzeTimingConsistency(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        self.engine.analyzeTimingConsistency(from: snapshots)
    }

    func analyzeTodoProductivity(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        self.engine.analyzeTodoProductivity(from: snapshots)
    }
}
