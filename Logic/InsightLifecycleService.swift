import FirebaseCore
import FirebaseFunctions
import Foundation
import OSLog

private let lifecycleLogger = Logger(subsystem: "com.yogaofeating", category: "InsightLifecycle")

private let lookbackDays = 7
private let minimumSnapshotsForBriefing = 2

// MARK: - Protocol

@MainActor
protocol InsightLifecycling {
    func generateEnrichedInsight(
        for date: Date,
        synthesis: DailySynthesis,
        recentSnapshots: [DailySmileySnapshot],
        healthKitSleepData: [Date: SleepData]
    ) async -> DailyInsight?

    func generateBriefing(
        for date: Date,
        healthKitSleepData: [Date: SleepData]
    ) async -> DailyInsight?
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

    // MARK: - Synthesis-driven insight (triggered by SynthesisScheduler)

    func generateEnrichedInsight(
        for date: Date,
        synthesis: DailySynthesis,
        recentSnapshots: [DailySmileySnapshot],
        healthKitSleepData _: [Date: SleepData]
    ) async -> DailyInsight? {
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

    // MARK: - Morning briefing (triggered by triggerBriefingGeneration)

    /// Generates a morning briefing as a unified `DailyInsight`.
    /// Replaces `BriefingService`: tries server first, falls back to local pattern analysis.
    func generateBriefing(
        for date: Date,
        healthKitSleepData: [Date: SleepData]
    ) async -> DailyInsight? {
        let snapshots = self.gatherRecentSnapshots(relativeTo: date)
        guard snapshots.count >= minimumSnapshotsForBriefing else { return nil }

        if let serverInsight = await self.generateBriefingFromServer(
            snapshots: snapshots,
            date: date,
            healthKitSleepData: healthKitSleepData
        ) {
            self.historicalService.updateInsight(for: date, insight: serverInsight)
            lifecycleLogger.info("Server briefing stored for \(date, privacy: .public)")
            return serverInsight
        }

        let localInsight = self.generateLocalBriefing(from: snapshots, date: date)
        self.historicalService.updateInsight(for: date, insight: localInsight)
        lifecycleLogger.info("Local briefing fallback stored for \(date, privacy: .public)")
        return localInsight
    }

    // MARK: - Server path

    private func generateBriefingFromServer(
        snapshots: [DailySmileySnapshot],
        date: Date,
        healthKitSleepData: [Date: SleepData]
    ) async -> DailyInsight? {
        guard let functions = self.functions else { return nil }

        let userData = SnapshotPayloadBuilder.build(
            from: Array(snapshots.prefix(lookbackDays)),
            healthKitSleepData: healthKitSleepData,
            relativeTo: date
        )

        do {
            let result = try await functions.httpsCallable("generateDailyBriefing").call(["userData": userData])
            guard let resp = result.data as? [String: Any],
                  let headline = resp["headline"] as? String,
                  let nudgeDict = resp["nudge"] as? [String: Any]
            else { return nil }

            let cards: [CorrelationCard] = (resp["correlationCards"] as? [[String: Any]] ?? []).compactMap { raw in
                guard let catStr = raw["category"] as? String,
                      let obs = raw["observation"] as? String,
                      let conf = raw["confidence"] as? Double,
                      let cat = CorrelationCategory(rawValue: catStr) else { return nil }
                return CorrelationCard(category: cat, observation: obs, confidence: conf)
            }

            let nudge = ActionableNudge(
                suggestion: nudgeDict["suggestion"] as? String ?? Strings.Insight.Nudge.defaultSuggestion,
                reasoning: nudgeDict["reasoning"] as? String ?? ""
            )

            var trend: WeeklyTrendSnippet?
            if let trendDict = resp["weeklyTrend"] as? [String: Any] {
                trend = WeeklyTrendSnippet(
                    averageFoodScore: trendDict["averageFoodScore"] as? Double ?? 0.5,
                    averageSleepQuality: trendDict["averageSleepQuality"] as? Double ?? 0.5,
                    daysLogged: trendDict["daysLogged"] as? Int ?? snapshots.count,
                    trendDirection: TrendDirection(rawValue: trendDict["trendDirection"] as? String ?? "steady") ??
                        .steady
                )
            }

            return DailyInsight(
                date: date,
                headline: headline,
                dimensions: WellbeingDimensions.neutral,
                dominantInsight: nudge.reasoning.isEmpty ? headline : nudge.reasoning,
                correlationCards: cards,
                nudge: nudge,
                weeklyTrend: trend,
                causalExplanation: nudge.reasoning,
                textSignals: [.neutral],
                confidence: cards.first?.confidence ?? 0.5
            )
        } catch {
            lifecycleLogger.error("Briefing server call failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - Local fallback

    private func generateLocalBriefing(from snapshots: [DailySmileySnapshot], date: Date) -> DailyInsight {
        let cards = self.patternAnalyzer.generateCorrelationCards(from: snapshots)
        let topCards = Array(cards.prefix(3))
        let avgScore = snapshots.map(\.averageHealthScore).average() ?? ScoringThresholds.neutral

        let headline = self.localHeadline(avgScore: avgScore, date: date)
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

    private func localHeadline(avgScore: Double, date _: Date) -> String {
        if avgScore > ScoringThresholds.high { return Strings.Insight.Headline.strong }
        if avgScore > ScoringThresholds.neutral { return Strings.Insight.Headline.steady }
        if avgScore > ScoringThresholds.unhealthy { return Strings.Insight.Headline.thoughtful }
        return Strings.Insight.Headline.challenging
    }

    private func localNudge(from cards: [CorrelationCard]) -> ActionableNudge {
        if let top = cards.first {
            return ActionableNudge(
                suggestion: "Focus on \(top.category.displayName.lowercased()) today",
                reasoning: top.observation
            )
        }
        return ActionableNudge(
            suggestion: Strings.Insight.Nudge.defaultSuggestion,
            reasoning: Strings.Insight.Nudge.defaultReasoning
        )
    }

    private func computeBriefingConfidence(cards: [CorrelationCard], snapshots: [DailySmileySnapshot]) -> Double {
        var score = 0.4
        if snapshots.count >= 5 { score += 0.2 }
        if let top = cards.first { score += top.confidence * 0.4 }
        return min(1.0, score)
    }

    // MARK: - Snapshot gathering

    private func gatherRecentSnapshots(relativeTo referenceDate: Date) -> [DailySmileySnapshot] {
        let calendar = Calendar.current
        return (0..<lookbackDays).compactMap { daysAgo -> DailySmileySnapshot? in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate) else { return nil }
            let snap = self.historicalService.getSnapshot(for: date)
            return snap?.isEmpty == false ? snap : nil
        }
    }

    // MARK: - Synthesis-path helpers

    private func buildLocalInsight(
        date: Date,
        synthesis: DailySynthesis,
        recentSnapshots: [DailySmileySnapshot]
    ) -> DailyInsight {
        let cards = self.patternAnalyzer.generateCorrelationCards(from: recentSnapshots)
        let topCards = Array(cards.prefix(3))
        let headline = self.synthesisHeadline(for: synthesis.dimensions.overall)
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

    private func synthesisHeadline(for overall: Double) -> String {
        if overall > SynthesisThresholds.overallHealthy { return Strings.EnrichedInsight.headlineStrong }
        if overall > SynthesisThresholds.overallNeutral { return Strings.EnrichedInsight.headlineSteady }
        if overall > SynthesisThresholds.overallThoughtful { return Strings.EnrichedInsight.headlineThoughtful }
        return Strings.EnrichedInsight.headlineChallenging
    }

    private func computeNudge(from cards: [CorrelationCard], synthesis: DailySynthesis) -> ActionableNudge {
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

    // MARK: - Weekly trend (shared by both paths)

    private func computeWeeklyTrend(from snapshots: [DailySmileySnapshot]) -> WeeklyTrendSnippet? {
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

    // MARK: - Confidence (synthesis path)

    private func computeConfidence(synthesis: DailySynthesis, snapshots: [DailySmileySnapshot]) -> Double {
        var score = 0.4
        if snapshots.count >= 5 { score += 0.2 }
        if synthesis.textSignals != [.neutral] { score += 0.2 }
        if synthesis.dimensions.physicalLoad != 0.5 { score += 0.1 }
        if synthesis.dimensions.cognitiveClarity != 0.5 { score += 0.1 }
        return min(1.0, score)
    }
}
