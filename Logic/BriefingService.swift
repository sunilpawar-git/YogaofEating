import FirebaseCore
import FirebaseFunctions
import Foundation
import OSLog

private let briefingServiceLogger = Logger(subsystem: "com.yogaofeating", category: "BriefingService")

/// Generates `DailyBriefing` objects from historical snapshot data.
///
/// Tries the server-side `generateDailyBriefing` Cloud Function first,
/// then falls back to local `PatternAnalyzer` + heuristic headline/nudge.
///
/// Extracted from `InsightGenerationService` (Phase 3C) to keep each type
/// under the 250-line limit and satisfy the Single Responsibility Principle.
@MainActor
final class BriefingService {
    // MARK: - Properties

    private let historicalService: any HistoricalDataServiceProtocol
    private let patternAnalyzer: PatternAnalyzer
    private var functions: Functions?

    /// Number of days to look back for briefing generation.
    private let lookbackDays: Int = 7

    // MARK: - Initialization

    init(
        historicalService: any HistoricalDataServiceProtocol,
        patternAnalyzer: PatternAnalyzer = PatternAnalyzer(),
        functions: Functions? = nil
    ) {
        self.historicalService = historicalService
        self.patternAnalyzer = patternAnalyzer

        if let providedFunctions = functions {
            self.functions = providedFunctions
        } else if FirebaseApp.app() != nil {
            self.functions = Functions.functions()
        } else {
            self.functions = nil
        }
    }

    // MARK: - Public API

    /// Generates a structured `DailyBriefing` from historical data.
    /// Returns `nil` if fewer than 2 snapshots are available.
    func generateBriefing(
        for date: Date,
        healthKitSleepData: [Date: SleepData] = [:]
    ) async -> DailyBriefing? {
        let snapshots = self.gatherRecentSnapshots(relativeTo: date)
        guard snapshots.count >= 2 else { return nil }

        if let serverBriefing = await self.generateBriefingFromServer(
            snapshots: snapshots,
            date: date,
            healthKitSleepData: healthKitSleepData
        ) {
            return serverBriefing
        }

        return self.generateLocalBriefing(from: snapshots, date: date)
    }

    // MARK: - Data Gathering

    private func gatherRecentSnapshots(relativeTo referenceDate: Date) -> [DailySmileySnapshot] {
        let calendar = Calendar.current
        return (0..<self.lookbackDays).compactMap { daysAgo -> DailySmileySnapshot? in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate) else { return nil }
            let snap = self.historicalService.getSnapshot(for: date)
            return snap?.isEmpty == false ? snap : nil
        }
    }

    // MARK: - Server-Side Briefing

    private func generateBriefingFromServer(
        snapshots: [DailySmileySnapshot],
        date: Date,
        healthKitSleepData: [Date: SleepData]
    ) async -> DailyBriefing? {
        guard let functions = self.functions else { return nil }

        let calendar = Calendar.current
        let todayNormalized = calendar.startOfDay(for: date)
        let recentSnapshots = Array(snapshots.prefix(self.lookbackDays))

        let userData: [[String: Any]] = recentSnapshots.map { snapshot in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            let dayName = formatter.string(from: snapshot.date)
            let isToday = calendar.isDate(snapshot.date, inSameDayAs: todayNormalized)

            var data: [String: Any] = [
                "date": dayName,
                "averageHealthScore": snapshot.averageHealthScore,
                "isToday": isToday
            ]

            if !snapshot.meals.isEmpty {
                data["meals"] = snapshot.meals.map { meal -> [String: Any] in
                    let timeFormatter = DateFormatter()
                    timeFormatter.timeStyle = .short
                    return [
                        "items": meal.items,
                        "healthScore": meal.healthScore,
                        "mealType": meal.mealType.rawValue,
                        "time": timeFormatter.string(from: meal.timestamp)
                    ]
                }
            }

            if let reflection = snapshot.reflection {
                if let sleep = reflection.sleepQuality { data["sleepQuality"] = sleep.displayName }
                if let feeling = reflection.feeling { data["feeling"] = feeling.displayName }
            }

            let snapshotDate = calendar.startOfDay(for: snapshot.date)
            if let sleepData = healthKitSleepData.first(where: {
                calendar.isDate($0.key, inSameDayAs: snapshotDate)
            })?.value {
                var apple: [String: Any] = [
                    "durationHours": sleepData.sleepDuration / 3600.0,
                    "efficiency": sleepData.efficiency
                ]
                if let score = sleepData.sleepScore { apple["score"] = score }
                data["appleSleepData"] = apple
            }

            if let morning = snapshot.morningMindCheck, !morning.isEmpty {
                data["morningMindCheck"] = morning.map { InsightServerFetcher.mindCheckEntryPayload($0) }
            }
            if let evening = snapshot.eveningMindCheck, !evening.isEmpty {
                data["eveningMindCheck"] = evening.map { InsightServerFetcher.mindCheckEntryPayload($0) }
            }

            return data
        }

        do {
            let result = try await functions.httpsCallable("generateDailyBriefing").call(["userData": userData])
            guard let resp = result.data as? [String: Any],
                  let headline = resp["headline"] as? String,
                  let nudgeDict = resp["nudge"] as? [String: Any] else { return nil }

            let cards: [CorrelationCard] = (resp["correlationCards"] as? [[String: Any]] ?? []).compactMap { raw in
                guard let catStr = raw["category"] as? String,
                      let obs = raw["observation"] as? String,
                      let conf = raw["confidence"] as? Double,
                      let cat = CorrelationCategory(rawValue: catStr) else { return nil }
                return CorrelationCard(category: cat, observation: obs, confidence: conf)
            }

            let nudge = ActionableNudge(
                suggestion: nudgeDict["suggestion"] as? String ?? "Keep going today!",
                reasoning: nudgeDict["reasoning"] as? String ?? "",
                relatedMeal: nudgeDict["relatedMeal"] as? String
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

            return DailyBriefing(
                date: date,
                generatedAt: Date(),
                headline: headline,
                correlationCards: cards,
                nudge: nudge,
                weeklyTrend: trend
            )
        } catch {
            briefingServiceLogger.error("Briefing server call failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - Local Briefing Fallback

    private func generateLocalBriefing(
        from snapshots: [DailySmileySnapshot],
        date: Date
    ) -> DailyBriefing {
        let correlationCards = self.patternAnalyzer.generateCorrelationCards(from: snapshots)

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayName = formatter.string(from: date)

        let avgScore = snapshots.map(\.averageHealthScore).average() ?? ScoringThresholds.neutral
        let headline = if avgScore > ScoringThresholds.high {
            "Great week! Your \(dayName) starts on a high note"
        } else if avgScore > ScoringThresholds.neutral {
            "Steady progress — here's your \(dayName) snapshot"
        } else {
            "Small shifts matter — your \(dayName) briefing"
        }

        let nudge = if let top = correlationCards.first {
            ActionableNudge(
                suggestion: "Focus on what worked: \(top.category.displayName.lowercased())",
                reasoning: top.observation
            )
        } else {
            ActionableNudge(
                suggestion: "Log your meals today to unlock deeper patterns",
                reasoning: "More data means richer insights tomorrow"
            )
        }

        var trend: WeeklyTrendSnippet?
        if snapshots.count >= 3 {
            let avgSleep = self.computeAverageSleepQuality(from: snapshots)
            let direction = self.computeTrendDirection(from: snapshots)
            trend = WeeklyTrendSnippet(
                averageFoodScore: avgScore,
                averageSleepQuality: avgSleep,
                daysLogged: snapshots.count,
                trendDirection: direction
            )
        }

        return DailyBriefing(
            date: date,
            generatedAt: Date(),
            headline: headline,
            correlationCards: correlationCards,
            nudge: nudge,
            weeklyTrend: trend
        )
    }

    // MARK: - Private Helpers

    private func computeAverageSleepQuality(from snapshots: [DailySmileySnapshot]) -> Double {
        let sleepScores: [Double] = snapshots.compactMap { snap -> Double? in
            guard let quality = snap.reflection?.sleepQuality else { return nil }
            return switch quality {
            case .great: 1.0
            case .good: 0.75
            case .poor: 0.25
            case .terrible: 0.0
            }
        }
        guard !sleepScores.isEmpty else { return 0.5 }
        return sleepScores.reduce(0, +) / Double(sleepScores.count)
    }

    private func computeTrendDirection(from snapshots: [DailySmileySnapshot]) -> TrendDirection {
        guard snapshots.count >= 3 else { return .steady }
        let scores = snapshots.reversed().map(\.averageHealthScore)
        let firstHalf = scores.prefix(scores.count / 2)
        let secondHalf = scores.suffix(scores.count / 2)
        let avgFirst = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let avgSecond = secondHalf.reduce(0, +) / Double(secondHalf.count)
        let delta = avgSecond - avgFirst
        if delta > ScoringThresholds.trendSignificanceDelta { return .improving }
        if delta < -ScoringThresholds.trendSignificanceDelta { return .declining }
        return .steady
    }
}
