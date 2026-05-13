import FirebaseCore
import FirebaseFunctions
import Foundation
import OSLog

private let lifecycleLogger = Logger(subsystem: "com.yogaofeating", category: "InsightLifecycle")

// MARK: - Protocol

@MainActor
protocol InsightLifecycling {
    func generateEnrichedInsight(
        for date: Date,
        synthesis: DailySynthesis,
        recentSnapshots: [DailySmileySnapshot],
        healthKitSleepData: [Date: SleepData]
    ) async -> EnrichedDailyInsight?
}

// MARK: - Implementation

@MainActor
final class InsightLifecycleService: InsightLifecycling {
    private let historicalService: any HistoricalDataServiceProtocol
    private let patternAnalyzer: PatternAnalyzer
    private var functions: Functions?

    private let minimumSnapshots: Int = 2

    init(
        historicalService: any HistoricalDataServiceProtocol,
        patternAnalyzer: PatternAnalyzer? = nil,
        functions: Functions? = nil
    ) {
        self.historicalService = historicalService
        self.patternAnalyzer = patternAnalyzer ?? PatternAnalyzer()
        if let provided = functions {
            self.functions = provided
        } else if FirebaseApp.app() != nil {
            self.functions = Functions.functions()
        } else {
            self.functions = nil
        }
    }

    func generateEnrichedInsight(
        for date: Date,
        synthesis: DailySynthesis,
        recentSnapshots: [DailySmileySnapshot],
        healthKitSleepData _: [Date: SleepData]
    ) async -> EnrichedDailyInsight? {
        guard recentSnapshots.count >= self.minimumSnapshots else { return nil }

        let insight = self.buildLocalInsight(
            date: date,
            synthesis: synthesis,
            recentSnapshots: recentSnapshots
        )

        self.historicalService.updateInsight(for: date, insight: insight)
        lifecycleLogger.info("Enriched insight generated for \(date, privacy: .public)")
        return insight
    }

    // MARK: - Local Generation

    private func buildLocalInsight(
        date: Date,
        synthesis: DailySynthesis,
        recentSnapshots: [DailySmileySnapshot]
    ) -> EnrichedDailyInsight {
        let cards = self.patternAnalyzer.generateCorrelationCards(from: recentSnapshots)
        let topCards = Array(cards.prefix(3))
        let headline = self.headline(for: synthesis.dimensions.overall)
        let nudge = self.computeNudge(from: topCards, synthesis: synthesis)
        let trend = self.computeWeeklyTrend(from: recentSnapshots)
        let confidence = self.computeConfidence(synthesis: synthesis, snapshots: recentSnapshots)

        return EnrichedDailyInsight(
            date: date,
            headline: headline,
            dimensions: synthesis.dimensions,
            dominantInsight: synthesis.causalNarrative,
            correlationCards: topCards,
            nudge: nudge,
            weeklyTrend: trend,
            causalExplanation: synthesis.causalNarrative,
            textSignals: synthesis.textSignals,
            confidence: confidence
        )
    }

    // MARK: - Headline

    private func headline(for overall: Double) -> String {
        if overall > SynthesisThresholds.overallHealthy { return Strings.EnrichedInsight.headlineStrong }
        if overall > SynthesisThresholds.overallNeutral { return Strings.EnrichedInsight.headlineSteady }
        if overall > SynthesisThresholds.overallThoughtful { return Strings.EnrichedInsight.headlineThoughtful }
        return Strings.EnrichedInsight.headlineChallenging
    }

    // MARK: - Nudge

    private func computeNudge(
        from cards: [CorrelationCard],
        synthesis: DailySynthesis
    ) -> ActionableNudge {
        if let top = cards.first {
            return ActionableNudge(
                suggestion: "Focus on \(top.category.displayName.lowercased()) today",
                reasoning: top.observation
            )
        }
        return self.defaultNudge(for: synthesis.dominantDimension)
    }

    private func defaultNudge(for dimension: WellbeingDimension) -> ActionableNudge {
        switch dimension {
        case .physicalLoad:
            ActionableNudge(
                suggestion: "Log your meals mindfully today",
                reasoning: Strings.Synthesis.CausalNarrative.physical
            )
        case .cognitiveClarity:
            ActionableNudge(
                suggestion: "Prioritise restful sleep tonight",
                reasoning: Strings.Synthesis.CausalNarrative.cognitive
            )
        case .emotionalTone:
            ActionableNudge(
                suggestion: "Take a moment to check in with how you feel",
                reasoning: Strings.Synthesis.CausalNarrative.emotional
            )
        case .behavioralMomentum:
            ActionableNudge(
                suggestion: "Pick one intention and follow through on it today",
                reasoning: Strings.Synthesis.CausalNarrative.behavioral
            )
        }
    }

    // MARK: - Weekly Trend

    private func computeWeeklyTrend(from snapshots: [DailySmileySnapshot]) -> WeeklyTrendSnippet? {
        guard snapshots.count >= 3 else { return nil }
        let scores = snapshots.map(\.averageHealthScore)
        let avgFood = scores.reduce(0, +) / Double(scores.count)
        let sleepScores: [Double] = snapshots.compactMap { snap -> Double? in
            snap.highlightData?.sleepQuality?.synthesisScore
        }
        let avgSleep = sleepScores.isEmpty ? 0.5 : sleepScores.reduce(0, +) / Double(sleepScores.count)
        let direction = self.trendDirection(from: scores)
        return WeeklyTrendSnippet(
            averageFoodScore: avgFood,
            averageSleepQuality: avgSleep,
            daysLogged: snapshots.count,
            trendDirection: direction
        )
    }

    private func trendDirection(from scores: [Double]) -> TrendDirection {
        guard scores.count >= 3 else { return .steady }
        let first = scores.prefix(scores.count / 2)
        let second = scores.suffix(scores.count / 2)
        let avgFirst = first.reduce(0, +) / Double(first.count)
        let avgSecond = second.reduce(0, +) / Double(second.count)
        let delta = avgSecond - avgFirst
        if delta > ScoringThresholds.trendSignificanceDelta { return .improving }
        if delta < -ScoringThresholds.trendSignificanceDelta { return .declining }
        return .steady
    }

    // MARK: - Confidence

    private func computeConfidence(
        synthesis: DailySynthesis,
        snapshots: [DailySmileySnapshot]
    ) -> Double {
        var score = 0.0
        score += 0.4 // baseline for having snapshots
        if snapshots.count >= 5 { score += 0.2 }
        if synthesis.textSignals != [.neutral] { score += 0.2 }
        if synthesis.dimensions.physicalLoad != 0.5 { score += 0.1 }
        if synthesis.dimensions.cognitiveClarity != 0.5 { score += 0.1 }
        return min(1.0, score)
    }
}
