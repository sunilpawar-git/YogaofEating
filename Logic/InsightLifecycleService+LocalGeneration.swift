import Foundation

/// Local insight generation helpers extracted from InsightLifecycleService
/// to keep InsightLifecycleService.swift under the 300-line limit.
extension InsightLifecycleService {
    // MARK: - Local briefing fallback

    func generateLocalBriefing(from snapshots: [DailySmileySnapshot], date: Date) -> DailyInsight {
        let cards = self.patternAnalyzer.generateCorrelationCards(from: snapshots)
        let topCards = Array(cards.prefix(3))
        let avgScore = snapshots.map(\.averageHealthScore).average() ?? ScoringThresholds.neutral

        let headline = self.localHeadline(avgScore: avgScore)
        let nudge = self.localNudge(from: topCards)
        let trend = self.computeWeeklyTrend(from: snapshots)
        let confidence = self.computeBriefingConfidence(cards: topCards, snapshots: snapshots)

        return DailyInsight(
            date: date,
            headline: headline,
            dimensions: WellbeingDimensions.neutral,
            dominantInsight: nudge.reasoning,
            correlationCards: topCards,
            nudge: nudge,
            weeklyTrend: trend,
            causalExplanation: nudge.reasoning,
            textSignals: [.neutral],
            confidence: confidence
        )
    }

    func localHeadline(avgScore: Double) -> String {
        if avgScore > ScoringThresholds.high { return Strings.Insight.Headline.strong }
        if avgScore > ScoringThresholds.neutral { return Strings.Insight.Headline.steady }
        if avgScore > ScoringThresholds.unhealthy { return Strings.Insight.Headline.thoughtful }
        return Strings.Insight.Headline.challenging
    }

    func localNudge(from cards: [CorrelationCard]) -> ActionableNudge {
        if let top = cards.first {
            return ActionableNudge(
                suggestion: String(
                    format: Strings.Insight.NudgeSuggestion.focusOnFmt,
                    top.category.displayName.lowercased()
                ),
                reasoning: top.observation
            )
        }
        return ActionableNudge(
            suggestion: Strings.Insight.Nudge.defaultSuggestion,
            reasoning: Strings.Insight.Nudge.defaultReasoning
        )
    }

    func computeBriefingConfidence(cards: [CorrelationCard], snapshots: [DailySmileySnapshot]) -> Double {
        var score = 0.4
        if snapshots.count >= 5 { score += 0.2 }
        if let top = cards.first { score += top.confidence * 0.4 }
        return min(1.0, score)
    }

    // MARK: - Synthesis-path helpers

    func buildLocalInsight(
        date: Date,
        synthesis: DailySynthesis,
        recentSnapshots: [DailySmileySnapshot]
    ) -> DailyInsight {
        let cards = self.patternAnalyzer.generateCorrelationCards(from: recentSnapshots)
        let topCards = Array(cards.prefix(3))
        let headline = self.synthesisHeadline(for: synthesis.overall)
        let nudge = self.computeNudge(from: topCards, synthesis: synthesis)
        let trend = self.computeWeeklyTrend(from: recentSnapshots)
        let confidence = self.computeConfidence(synthesis: synthesis, snapshots: recentSnapshots)

        return DailyInsight(
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

    func synthesisHeadline(for overall: Double) -> String {
        if overall > SynthesisThresholds.overallHealthy { return Strings.EnrichedInsight.headlineStrong }
        if overall > SynthesisThresholds.overallNeutral { return Strings.EnrichedInsight.headlineSteady }
        if overall > SynthesisThresholds.overallThoughtful { return Strings.EnrichedInsight.headlineThoughtful }
        return Strings.EnrichedInsight.headlineChallenging
    }

    func computeNudge(from cards: [CorrelationCard], synthesis: DailySynthesis) -> ActionableNudge {
        if let top = cards.first {
            return ActionableNudge(
                suggestion: String(
                    format: Strings.Insight.NudgeSuggestion.focusOnFmt,
                    top.category.displayName.lowercased()
                ),
                reasoning: top.observation
            )
        }
        return self.defaultNudge(for: synthesis.dominantDimension)
    }

    func defaultNudge(for dimension: WellbeingDimension) -> ActionableNudge {
        switch dimension {
        case .physicalLoad:
            ActionableNudge(
                suggestion: Strings.Insight.NudgeSuggestion.physical,
                reasoning: Strings.Synthesis.CausalNarrative.physical
            )
        case .cognitiveClarity:
            ActionableNudge(
                suggestion: Strings.Insight.NudgeSuggestion.cognitive,
                reasoning: Strings.Synthesis.CausalNarrative.cognitive
            )
        case .emotionalTone:
            ActionableNudge(
                suggestion: Strings.Insight.NudgeSuggestion.emotional,
                reasoning: Strings.Synthesis.CausalNarrative.emotional
            )
        case .behavioralMomentum:
            ActionableNudge(
                suggestion: Strings.Insight.NudgeSuggestion.behavioral,
                reasoning: Strings.Synthesis.CausalNarrative.behavioral
            )
        }
    }

    // MARK: - Weekly trend (shared by both paths)

    func computeWeeklyTrend(from snapshots: [DailySmileySnapshot]) -> WeeklyTrendSnippet? {
        guard snapshots.count >= 3 else { return nil }
        let scores = snapshots.map(\.averageHealthScore)
        let avgFood = scores.reduce(0, +) / Double(scores.count)
        let sleepScores: [Double] = snapshots.compactMap { $0.reflection?.sleepQuality?.synthesisScore }
        let avgSleep = sleepScores.isEmpty ? 0.5 : sleepScores.reduce(0, +) / Double(sleepScores.count)
        return WeeklyTrendSnippet(
            averageFoodScore: avgFood,
            averageSleepQuality: avgSleep,
            daysLogged: snapshots.count,
            trendDirection: self.trendDirection(from: scores)
        )
    }

    func trendDirection(from scores: [Double]) -> TrendDirection {
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

    // MARK: - Confidence (synthesis path)

    func computeConfidence(synthesis: DailySynthesis, snapshots: [DailySmileySnapshot]) -> Double {
        var score = 0.4
        if snapshots.count >= 5 { score += 0.2 }
        if synthesis.textSignals != [.neutral] { score += 0.2 }
        if synthesis.dataCompleteness.contains(.physicalLoad) { score += 0.1 }
        if synthesis.dataCompleteness.contains(.cognitiveClarity) { score += 0.1 }
        return min(1.0, score)
    }
}
