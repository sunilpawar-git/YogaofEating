import FirebaseCore
import FirebaseFunctions
import Foundation
import OSLog

private let briefingLogger = Logger(subsystem: "com.yogaofeating", category: "Briefing")

/// Payload-shaping constants for the insight data sent to the server.
enum InsightPayloadConstants {
    /// Maximum number of meal items included per daily snapshot in the server payload.
    static let maxMealItemsPerSnapshot: Int = 5
}

/// Protocol for insight generation to enable testing.
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

/// Orchestrates AI-powered insight generation from user data.
/// Delegates daily briefing generation to `BriefingService` and pattern analysis
/// to `PatternAnalyzer`/`PatternAnalysisEngine` — single responsibility.
@MainActor
class InsightGenerationService: InsightGenerationServiceProtocol {
    // MARK: - Properties

    private let historicalService: any HistoricalDataServiceProtocol
    private let patternAnalyzer: PatternAnalyzer
    private let briefingService: BriefingService
    private var functions: Functions?

    private let lookbackDays: Int = 7
    private let serverLookbackDays: Int = 3

    // MARK: - Initialization

    init(
        historicalService: any HistoricalDataServiceProtocol,
        functions: Functions? = nil
    ) {
        self.historicalService = historicalService
        self.patternAnalyzer = PatternAnalyzer()
        self.briefingService = BriefingService(historicalService: historicalService, functions: functions)

        if let providedFunctions = functions {
            self.functions = providedFunctions
        } else if FirebaseApp.app() != nil {
            self.functions = Functions.functions()
        } else {
            self.functions = nil
        }
    }

    // MARK: - Data Gathering

    /// Public protocol method — defaults lookback to today for callers without a reference date.
    func gatherDataForInsight() -> [DailySmileySnapshot] {
        self.gatherDataForInsight(relativeTo: Date())
    }

    /// Internal overload anchored to a specific reference date.
    /// Used by `generateInsight(for:)` so the lookback window matches the requested date.
    private func gatherDataForInsight(relativeTo referenceDate: Date) -> [DailySmileySnapshot] {
        let calendar = Calendar.current
        return (0..<self.lookbackDays).compactMap { daysAgo -> DailySmileySnapshot? in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate) else { return nil }
            let snap = self.historicalService.getSnapshot(for: date)
            return snap?.isEmpty == false ? snap : nil
        }
    }

    // MARK: - Prompt Creation

    func createInsightPrompt(from snapshots: [DailySmileySnapshot]) -> String {
        var parts: [String] = [
            "Analyze the following wellbeing data from the past week and provide a brief, actionable insight.",
            ""
        ]

        for snapshot in snapshots.prefix(7) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            let dayName = dateFormatter.string(from: snapshot.date)
            var dayData = ["**\(dayName)**:"]

            if !snapshot.meals.isEmpty {
                let mealItems = snapshot.meals.flatMap(\.items)
                    .prefix(InsightPayloadConstants.maxMealItemsPerSnapshot)
                    .joined(separator: ", ")
                dayData.append("  Food: \(mealItems)")
                dayData.append("  Health Score: \(String(format: "%.0f%%", snapshot.averageHealthScore * 100))")
            }
            if let reflection = snapshot.reflection {
                if let sleep = reflection.sleepQuality { dayData.append("  Sleep: \(sleep.displayName)") }
                if let feeling = reflection.feeling { dayData.append("  Feeling: \(feeling.displayName)") }
            }
            if let morningEntries = snapshot.morningMindCheck, !morningEntries.isEmpty {
                let todos = morningEntries.filter { $0.category == .todo }
                if !todos.isEmpty {
                    let completedCount = todos.count(where: { $0.isAccomplished == true })
                    dayData.append("  Todos: \(completedCount)/\(todos.count) completed")
                }
                let other = morningEntries.filter { $0.category != .todo }
                    .map { "\($0.category.displayName): \($0.text)" }
                if !other.isEmpty { dayData.append("  Morning thoughts: \(other.joined(separator: "; "))") }
            }
            if let eveningEntries = snapshot.eveningMindCheck, !eveningEntries.isEmpty {
                let refs = eveningEntries.map { "\($0.category.displayName): \($0.text)" }.joined(separator: "; ")
                dayData.append("  Evening reflections: \(refs)")
            }
            parts.append(contentsOf: dayData)
            parts.append("")
        }

        parts += [
            "Provide a single, personalized insight (2-3 sentences max) that:",
            "1. Identifies a pattern between food choices and sleep/mood/energy",
            "2. Is encouraging and actionable",
            "3. Does not repeat previous insights"
        ]
        return parts.joined(separator: "\n")
    }

    // MARK: - Insight Storage

    func saveInsight(_ insight: LegacyDailyInsight, for date: Date) {
        self.historicalService.updateInsight(for: date, insight: insight)
        briefingLogger.info("Insight saved for date \(date, privacy: .public)")
    }

    // MARK: - Check Methods

    func shouldGenerateInsight(for date: Date) -> Bool {
        guard let snapshot = historicalService.getSnapshot(for: date),
              let reflection = snapshot.reflection,
              reflection.sleepQuality != nil else { return false }
        return self.gatherDataForInsight(relativeTo: date).count >= BriefingThresholds.minimumDataPoints
    }

    // MARK: - Insight Generation

    func generateInsight(
        for date: Date,
        healthKitSleepData: [Date: SleepData] = [:]
    ) async throws -> LegacyDailyInsight? {
        guard self.shouldGenerateInsight(for: date) else { return nil }

        let snapshots = self.gatherDataForInsight(relativeTo: date)
        let recentSnapshots = Array(snapshots.prefix(self.serverLookbackDays))

        if let serverInsight = await generateInsightFromServer(
            snapshots: recentSnapshots,
            date: date,
            healthKitSleepData: healthKitSleepData
        ) {
            briefingLogger.info("Using server-generated insight from Gemini")
            self.saveInsight(serverInsight, for: date)
            return serverInsight
        }

        briefingLogger.info("Using local PatternAnalyzer for insight generation")
        let patterns = self.patternAnalyzer.analyzePatterns(from: snapshots)
        let (insightText, insightType, references, confidence) = self.generateRichInsight(
            from: snapshots, patterns: patterns
        )
        let insight = LegacyDailyInsight(
            date: date,
            insightText: insightText,
            insightType: insightType,
            confidence: confidence,
            references: references
        )
        self.saveInsight(insight, for: date)
        return insight
    }

    // MARK: - Briefing (delegates to BriefingService)

    func generateBriefing(for date: Date, healthKitSleepData: [Date: SleepData] = [:]) async -> DailyBriefing? {
        await self.briefingService.generateBriefing(for: date, healthKitSleepData: healthKitSleepData)
    }

    // MARK: - Weekly Insight

    func generateWeeklyInsight() async -> WeeklyInsight? {
        let snapshots = self.gatherDataForInsight()
        guard snapshots.count >= 3 else { return nil }

        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else {
            briefingLogger.error("Failed to compute weekStart — skipping weekly insight")
            return nil
        }

        let patterns = self.patternAnalyzer.analyzePatterns(from: snapshots)
        let (summaryText, wins, improvements) = self.generateWeeklySummary(from: snapshots, patterns: patterns)

        return WeeklyInsight(
            weekStartDate: weekStart,
            weekEndDate: today,
            summaryText: summaryText,
            topPatterns: Array(patterns.prefix(BriefingThresholds.maximumInsightReferences)),
            dailyInsights: [],
            improvementAreas: improvements,
            wins: wins
        )
    }

    // MARK: - Private Helpers

    private func generateInsightFromServer(
        snapshots: [DailySmileySnapshot],
        date: Date,
        healthKitSleepData: [Date: SleepData]
    ) async -> LegacyDailyInsight? {
        guard let functions = self.functions else {
            briefingLogger.info("Firebase Functions not available — skipping server insight")
            return nil
        }
        return await InsightServerFetcher.fetchInsight(
            snapshots: snapshots,
            date: date,
            healthKitSleepData: healthKitSleepData,
            functions: functions
        )
    }

    private func generateRichInsight(
        from snapshots: [DailySmileySnapshot],
        patterns: [InsightPattern]
    ) -> (text: String, type: InsightType, references: [InsightReference], confidence: Double) {
        LocalInsightGenerator.generateRichInsight(from: snapshots, patterns: patterns)
    }

    private func generateWeeklySummary(
        from snapshots: [DailySmileySnapshot],
        patterns: [InsightPattern]
    ) -> (summary: String, wins: [String], improvements: [String]) {
        LocalInsightGenerator.generateWeeklySummary(from: snapshots, patterns: patterns)
    }
}
