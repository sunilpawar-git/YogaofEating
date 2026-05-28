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
        userContext: BriefingUserContext?,
        nudgeHistory: [NudgeHistoryEntry],
        healthKitSleepData: [Date: SleepData]
    ) async -> DailyInsight?
}

// MARK: - Implementation

@MainActor
final class InsightLifecycleService: InsightLifecycling {
    private let historicalService: any HistoricalDataServiceProtocol
    let patternAnalyzer: PatternAnalysisEngine
    private var functions: Functions?

    private let minimumSnapshots: Int = 2

    init(
        historicalService: any HistoricalDataServiceProtocol,
        patternAnalyzer: PatternAnalysisEngine? = nil,
        functions: Functions? = nil
    ) {
        self.historicalService = historicalService
        self.patternAnalyzer = patternAnalyzer ?? PatternAnalysisEngine()
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

    // MARK: - Snapshot gathering

    private func gatherRecentSnapshots(relativeTo referenceDate: Date) -> [DailySmileySnapshot] {
        let calendar = Calendar.current
        return (0..<lookbackDays).compactMap { daysAgo -> DailySmileySnapshot? in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate) else { return nil }
            let snap = self.historicalService.getSnapshot(for: date)
            return snap?.isEmpty == false ? snap : nil
        }
    }

    // MARK: - Morning briefing (triggered by triggerBriefingGeneration)

    /// Generates a morning briefing as a unified `DailyInsight`.
    /// Replaces `BriefingService`: tries server first, falls back to local pattern analysis.
    func generateBriefing(
        for date: Date,
        userContext: BriefingUserContext?,
        nudgeHistory: [NudgeHistoryEntry],
        healthKitSleepData: [Date: SleepData]
    ) async -> DailyInsight? {
        let snapshots = self.gatherRecentSnapshots(relativeTo: date)
        guard snapshots.count >= minimumSnapshotsForBriefing else { return nil }

        if let serverInsight = await self.generateBriefingFromServer(
            snapshots: snapshots,
            date: date,
            userContext: userContext,
            nudgeHistory: nudgeHistory,
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
        userContext: BriefingUserContext?,
        nudgeHistory: [NudgeHistoryEntry],
        healthKitSleepData: [Date: SleepData]
    ) async -> DailyInsight? {
        guard let functions = self.functions else { return nil }

        let historicalSummary = self.historicalService.computeHistoricalSummary(relativeTo: date)
        let callPayload = SnapshotPayloadBuilder.build(
            from: Array(snapshots.prefix(lookbackDays)),
            userContext: userContext,
            nudgeHistory: nudgeHistory,
            historicalSummary: historicalSummary,
            healthKitSleepData: healthKitSleepData,
            relativeTo: date
        )

        do {
            let result = try await functions.httpsCallable("generateDailyBriefing").call(callPayload)
            guard let resp = result.data as? [String: Any],
                  let headline = resp["headline"] as? String,
                  let nudgeDict = resp["nudge"] as? [String: Any]
            else { return nil }

            let cards: [CorrelationCard] = (resp["correlationCards"] as? [[String: Any]] ?? []).compactMap { raw in
                guard let catStr = raw["category"] as? String,
                      let obs = raw["observation"] as? String,
                      let conf = raw["confidence"] as? Double,
                      let cat = CorrelationCategory(rawValue: catStr) else { return nil }
                let refs = raw["dataReferences"] as? [String]
                return CorrelationCard(category: cat, observation: obs, confidence: conf, dataReferences: refs)
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
            lifecycleLogger.error("Briefing server call failed: \(error.localizedDescription, privacy: .private)")
            return nil
        }
    }
}
