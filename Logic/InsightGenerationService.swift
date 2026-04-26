import FirebaseCore
import FirebaseFunctions
import Foundation

@MainActor
protocol InsightGenerationServiceProtocol {
    func gatherDataForInsight() -> [DailySmileySnapshot]
    func createInsightPrompt(from snapshots: [DailySmileySnapshot]) -> String
    func saveInsight(_ insight: DailyInsight, for date: Date)
    func shouldGenerateInsight(for date: Date) -> Bool
    func generateInsight(for date: Date, healthKitSleepData: [Date: SleepData]) async throws -> DailyInsight?
    func generateWeeklyInsight() async -> WeeklyInsight?
}

/// Service for generating AI-powered insights from user data.
/// Correlates food, mindset, sleep, and feeling data to provide personalized insights.
/// Tries server-side Gemini generation first, falls back to local PatternAnalyzer.
@MainActor
class InsightGenerationService: InsightGenerationServiceProtocol {
    // MARK: - Properties

    private let historicalService: any HistoricalDataServiceProtocol
    private let patternAnalyzer: PatternAnalyzer
    private(set) var functions: Functions?

    /// Number of days to look back for insight generation
    private let lookbackDays: Int = 7

    /// Number of days to send to server (last 1-3 days for focused insights)
    private let serverLookbackDays: Int = 3

    // MARK: - Initialization

    init(historicalService: any HistoricalDataServiceProtocol, functions: Functions? = nil) {
        self.historicalService = historicalService
        self.patternAnalyzer = PatternAnalyzer()

        // Only initialize Firebase Functions if Firebase is configured
        if let providedFunctions = functions {
            self.functions = providedFunctions
        } else if FirebaseApp.app() != nil {
            self.functions = Functions.functions()
        } else {
            self.functions = nil
        }
    }

    // MARK: - Data Gathering

    /// Gathers the last 7 days of data for insight generation.
    /// Excludes empty days (no meals logged).
    /// - Returns: Array of snapshots with actual data
    func gatherDataForInsight() -> [DailySmileySnapshot] {
        let calendar = Calendar.current
        var snapshots: [DailySmileySnapshot] = []

        for daysAgo in 0..<self.lookbackDays {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            if let snapshot = self.historicalService.getSnapshot(for: date), !snapshot.isEmpty {
                snapshots.append(snapshot)
            }
        }

        return snapshots
    }

    // MARK: - Prompt Creation

    /// Creates a prompt for the AI to generate insights.
    func createInsightPrompt(from snapshots: [DailySmileySnapshot]) -> String {
        InsightPromptBuilder.dailyPrompt(from: snapshots)
    }

    // MARK: - Insight Storage

    /// Saves a generated insight for a specific date.
    /// - Parameters:
    ///   - insight: The insight to save
    ///   - date: The date to associate the insight with
    func saveInsight(_ insight: DailyInsight, for date: Date) {
        self.historicalService.updateDailyInsight(for: date, insight: insight)
    }

    // MARK: - Check Methods

    /// Determines whether an insight should be generated for the given date.
    /// Returns true if: sleep quality is logged AND no insight generated yet today.
    /// - Parameter date: The date to check
    /// - Returns: True if insight should be generated
    func shouldGenerateInsight(for date: Date) -> Bool {
        guard let snapshot = self.historicalService.getSnapshot(for: date) else {
            return false
        }

        // Must have sleep quality logged (morning trigger)
        guard let reflection = snapshot.reflection, reflection.sleepQuality != nil else {
            return false
        }

        // Must have some historical data to analyze
        let data = self.gatherDataForInsight()
        guard data.count >= 2 else {
            return false
        }

        return true
    }

    // MARK: - Insight Generation

    /// Generates an insight for the given date using AI.
    /// Tries server-side Gemini generation first, falls back to local PatternAnalyzer.
    /// - Parameters:
    ///   - date: The date to generate insight for
    ///   - healthKitSleepData: Dictionary mapping dates to HealthKit sleep data for objective metrics
    /// - Returns: A generated insight, or nil if conditions aren't met
    func generateInsight(for date: Date, healthKitSleepData: [Date: SleepData] = [:]) async throws -> DailyInsight? {
        guard self.shouldGenerateInsight(for: date) else {
            return nil
        }

        let snapshots = self.gatherDataForInsight()

        // Try server-side generation first (last 1-3 days for focused insights)
        let recentSnapshots = Array(snapshots.prefix(self.serverLookbackDays))
        if let serverInsight = await self.generateInsightFromServer(
            snapshots: recentSnapshots,
            date: date,
            healthKitSleepData: healthKitSleepData
        ) {
            #if DEBUG
                print("✨ Using server-generated insight from Gemini")
            #endif
            self.saveInsight(serverInsight, for: date)
            return serverInsight
        }

        // Fallback to local PatternAnalyzer
        #if DEBUG
            print("📊 Using local PatternAnalyzer for insight generation")
        #endif
        let patterns = self.patternAnalyzer.analyzePatterns(from: snapshots)

        // Generate insight based on detected patterns or fallback to generic
        let richInsight = self.generateRichInsight(
            from: snapshots,
            patterns: patterns
        )

        let insight = DailyInsight(
            date: date,
            insightText: richInsight.text,
            insightType: richInsight.type,
            confidence: richInsight.confidence,
            references: richInsight.references
        )

        self.saveInsight(insight, for: date)
        return insight
    }

    // MARK: - Weekly Insight Generation

    /// Generates a weekly insight aggregating the past 7 days of data.
    func generateWeeklyInsight() async -> WeeklyInsight? {
        let snapshots = self.gatherDataForInsight()
        let patterns = self.patternAnalyzer.analyzePatterns(from: snapshots)
        let dailyInsights = snapshots.compactMap(\.dailyInsight)
        return WeeklyInsightGenerator.generate(
            snapshots: snapshots,
            patterns: patterns,
            patternAnalyzer: self.patternAnalyzer,
            dailyInsights: dailyInsights
        )
    }
}
