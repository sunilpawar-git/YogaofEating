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
    let patternAnalyzer: PatternAnalyzer
    private var functions: Functions?

    /// Number of days to look back for briefing generation.
    private let lookbackDays: Int = 7

    // MARK: - Initialization

    init(
        historicalService: any HistoricalDataServiceProtocol,
        patternAnalyzer: PatternAnalyzer? = nil,
        functions: Functions? = nil
    ) {
        self.historicalService = historicalService
        self.patternAnalyzer = patternAnalyzer ?? PatternAnalyzer()

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
}
