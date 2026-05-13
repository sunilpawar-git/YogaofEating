import FirebaseCore
import FirebaseFunctions
import Foundation
import OSLog

private let briefingLogger = Logger(subsystem: "com.yogaofeating", category: "Briefing")

/// Payload-shaping constants for the insight data sent to the server.
enum InsightPayloadConstants {
    static let maxMealItemsPerSnapshot: Int = 5
}

/// Thin shell — all generation delegates to InsightLifecycleService.
/// Deleted in Phase 4 when MainViewModel wires directly to InsightLifecycleService.
@MainActor
protocol InsightGenerationServiceProtocol {
    func gatherDataForInsight() -> [DailySmileySnapshot]
    func createInsightPrompt(from snapshots: [DailySmileySnapshot]) -> String
    func saveInsight(_ insight: LegacyDailyInsight, for date: Date)
    func shouldGenerateInsight(for date: Date) -> Bool
    func generateInsight(for date: Date, healthKitSleepData: [Date: SleepData]) async throws -> LegacyDailyInsight?
    func generateWeeklyInsight() async -> WeeklyInsight?
    func generateBriefing(for date: Date, healthKitSleepData: [Date: SleepData]) async -> DailyBriefing?
}

extension InsightGenerationServiceProtocol {
    func generateBriefing(for date: Date) async -> DailyBriefing? {
        await self.generateBriefing(for: date, healthKitSleepData: [:])
    }
}

@MainActor
class InsightGenerationService: InsightGenerationServiceProtocol {
    private let historicalService: any HistoricalDataServiceProtocol
    private let patternAnalyzer: PatternAnalyzer
    private let lifecycleService: InsightLifecycleService

    private let lookbackDays: Int = 7

    init(
        historicalService: any HistoricalDataServiceProtocol,
        functions: Functions? = nil
    ) {
        self.historicalService = historicalService
        self.patternAnalyzer = PatternAnalyzer()
        self.lifecycleService = InsightLifecycleService(
            historicalService: historicalService,
            functions: functions
        )
    }

    // MARK: - Data gathering (still used by shouldGenerateInsight + tests)

    func gatherDataForInsight() -> [DailySmileySnapshot] {
        self.gatherDataForInsight(relativeTo: Date())
    }

    private func gatherDataForInsight(relativeTo referenceDate: Date) -> [DailySmileySnapshot] {
        let calendar = Calendar.current
        return (0..<self.lookbackDays).compactMap { daysAgo -> DailySmileySnapshot? in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate) else { return nil }
            let snap = self.historicalService.getSnapshot(for: date)
            return snap?.isEmpty == false ? snap : nil
        }
    }

    // MARK: - Prompt (still used by some tests)

    func createInsightPrompt(from snapshots: [DailySmileySnapshot]) -> String {
        var parts: [String] = [
            "Analyze the following wellbeing data from the past week and provide a brief, actionable insight.",
            ""
        ]
        for snapshot in snapshots.prefix(7) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            var dayData = ["**\(formatter.string(from: snapshot.date))**:"]
            if !snapshot.meals.isEmpty {
                let items = snapshot.meals.flatMap(\.items)
                    .prefix(InsightPayloadConstants.maxMealItemsPerSnapshot)
                    .joined(separator: ", ")
                dayData.append("  Food: \(items)")
                dayData.append("  Health Score: \(String(format: "%.0f%%", snapshot.averageHealthScore * 100))")
            }
            if let reflection = snapshot.reflection {
                if let sleep = reflection.sleepQuality { dayData.append("  Sleep: \(sleep.displayName)") }
                if let feeling = reflection.feeling { dayData.append("  Feeling: \(feeling.displayName)") }
            }
            if let morning = snapshot.morningMindCheck, !morning.isEmpty {
                let todos = morning.filter { $0.category == .todo }
                if !todos.isEmpty {
                    dayData
                        .append(
                            "  Todos: \(todos.count(where: { $0.isAccomplished == true }))/\(todos.count) completed"
                        )
                }
            }
            parts.append(contentsOf: dayData)
            parts.append("")
        }
        parts += [
            "Provide a single, personalized insight (2-3 sentences max) that:",
            "1. Identifies a pattern between food choices and sleep/mood/energy",
            "2. Is encouraging and actionable"
        ]
        return parts.joined(separator: "\n")
    }

    // MARK: - No-ops (Phase 3 tech debt — deleted with class in Phase 4)

    func saveInsight(_: LegacyDailyInsight, for date: Date) {
        briefingLogger.info("Legacy saveInsight suppressed in Phase 3; date \(date, privacy: .public)")
    }

    func shouldGenerateInsight(for date: Date) -> Bool {
        guard let snapshot = historicalService.getSnapshot(for: date),
              let reflection = snapshot.reflection,
              reflection.sleepQuality != nil else { return false }
        return self.gatherDataForInsight(relativeTo: date).count >= BriefingThresholds.minimumDataPoints
    }

    func generateInsight(
        for _: Date,
        healthKitSleepData _: [Date: SleepData] = [:]
    ) async throws -> LegacyDailyInsight? {
        // Legacy pipeline suppressed — InsightLifecycleService owns generation. Deleted in Phase 4.
        nil
    }

    func generateWeeklyInsight() async -> WeeklyInsight? {
        // Legacy weekly insight suppressed — deleted in Phase 4.
        nil
    }

    // MARK: - Briefing (delegates to InsightLifecycleService)

    func generateBriefing(for date: Date, healthKitSleepData: [Date: SleepData] = [:]) async -> DailyBriefing? {
        guard let insight = await lifecycleService.generateBriefing(
            for: date,
            healthKitSleepData: healthKitSleepData
        ) else { return nil }
        return DailyBriefing(insight: insight)
    }
}
