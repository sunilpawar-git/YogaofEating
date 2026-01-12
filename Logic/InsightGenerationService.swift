import Foundation

/// Protocol for insight generation to enable testing.
@MainActor
protocol InsightGenerationServiceProtocol {
    func gatherDataForInsight() -> [DailySmileySnapshot]
    func createInsightPrompt(from snapshots: [DailySmileySnapshot]) -> String
    func saveInsight(_ insight: DailyInsight, for date: Date)
    func shouldGenerateInsight(for date: Date) -> Bool
    func generateInsight(for date: Date) async throws -> DailyInsight?
}

/// Service for generating AI-powered insights from user data.
/// Correlates food, mindset, sleep, and feeling data to provide personalized insights.
@MainActor
class InsightGenerationService: InsightGenerationServiceProtocol {
    // MARK: - Properties

    private let historicalService: any HistoricalDataServiceProtocol

    /// Number of days to look back for insight generation
    private let lookbackDays: Int = 7

    // MARK: - Initialization

    init(historicalService: any HistoricalDataServiceProtocol) {
        self.historicalService = historicalService
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
    /// Includes meals, sleep, mindset, and feeling data.
    /// - Parameter snapshots: The snapshots to include in the prompt
    /// - Returns: A formatted prompt string for the AI
    func createInsightPrompt(from snapshots: [DailySmileySnapshot]) -> String {
        var promptParts: [String] = []

        promptParts
            .append("Analyze the following wellbeing data from the past week and provide a brief, actionable insight.")
        promptParts.append("")

        for snapshot in snapshots.prefix(7) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            let dayName = dateFormatter.string(from: snapshot.date)

            var dayData: [String] = []
            dayData.append("**\(dayName)**:")

            // Meals
            if !snapshot.meals.isEmpty {
                let mealItems = snapshot.meals.flatMap(\.items).prefix(5).joined(separator: ", ")
                dayData.append("  Food: \(mealItems)")
                dayData.append("  Health Score: \(String(format: "%.0f%%", snapshot.averageHealthScore * 100))")
            }

            // Sleep quality
            if let reflection = snapshot.reflection, let sleep = reflection.sleepQuality {
                dayData.append("  Sleep: \(sleep.displayName)")
            }

            // Feeling
            if let reflection = snapshot.reflection, let feeling = reflection.feeling {
                dayData.append("  Feeling: \(feeling.displayName)")
            }

            // Morning mind check
            if let morningEntries = snapshot.morningMindCheck, !morningEntries.isEmpty {
                let thoughts = morningEntries.map { "\($0.category.displayName): \($0.text)" }.joined(separator: "; ")
                dayData.append("  Morning thoughts: \(thoughts)")
            }

            // Evening mind check
            if let eveningEntries = snapshot.eveningMindCheck, !eveningEntries.isEmpty {
                let reflections = eveningEntries.map { "\($0.category.displayName): \($0.text)" }
                    .joined(separator: "; ")
                dayData.append("  Evening reflections: \(reflections)")
            }

            promptParts.append(contentsOf: dayData)
            promptParts.append("")
        }

        promptParts.append("Provide a single, personalized insight (2-3 sentences max) that:")
        promptParts.append("1. Identifies a pattern between food choices and sleep/mood/energy")
        promptParts.append("2. Is encouraging and actionable")
        promptParts.append("3. Does not repeat previous insights")

        return promptParts.joined(separator: "\n")
    }

    // MARK: - Insight Storage

    /// Saves a generated insight for a specific date.
    /// - Parameters:
    ///   - insight: The insight to save
    ///   - date: The date to associate the insight with
    func saveInsight(_ insight: DailyInsight, for _: Date) {
        // TODO: Implement storage - will be added in future phase
        // For now, insights are ephemeral
        print("📊 Insight generated: \(insight.insightText)")
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
    /// - Parameter date: The date to generate insight for
    /// - Returns: A generated insight, or nil if conditions aren't met
    func generateInsight(for date: Date) async throws -> DailyInsight? {
        guard self.shouldGenerateInsight(for: date) else {
            return nil
        }

        let snapshots = self.gatherDataForInsight()
        let prompt = self.createInsightPrompt(from: snapshots)

        // For now, return a placeholder insight
        // In production, this would call the Gemini API
        let insightText = self.generateLocalInsight(from: snapshots)

        let insight = DailyInsight(
            date: date,
            insightText: insightText,
            insightType: determineInsightType(from: snapshots),
            confidence: 0.7
        )

        self.saveInsight(insight, for: date)
        return insight
    }

    // MARK: - Private Helpers

    private func generateLocalInsight(from snapshots: [DailySmileySnapshot]) -> String {
        // Simple local insight generation (fallback when AI unavailable)
        guard let yesterday = snapshots.first else {
            return "Keep logging your meals and sleep to discover patterns in your wellbeing."
        }

        let avgScore = snapshots.map(\.averageHealthScore).reduce(0, +) / Double(snapshots.count)

        if avgScore > 0.7 {
            return "Great job! Your healthy eating choices over the past week are likely contributing to better energy and sleep. Keep it up! 💪"
        } else if avgScore > 0.5 {
            return "You're on the right track. Try adding more vegetables to your evening meals - they may help improve your sleep quality."
        } else {
            return "Consider lighter, more balanced meals - heavy or processed foods late in the day can affect how you feel the next morning."
        }
    }

    private func determineInsightType(from snapshots: [DailySmileySnapshot]) -> InsightType {
        // Check what data we have to determine the best insight type
        let hasSleepData = snapshots.contains { $0.reflection?.sleepQuality != nil }
        let hasMindCheckData = snapshots.contains { $0.hasMorningMindCheck || $0.hasEveningMindCheck }
        let hasFeelingData = snapshots.contains { $0.reflection?.feeling != nil }

        if hasSleepData, snapshots.count >= 3 {
            return .foodSleep
        } else if hasMindCheckData, hasFeelingData {
            return .mindsetFeeling
        } else if snapshots.count >= 5 {
            return .pattern
        } else {
            return .encouragement
        }
    }
}
