import Foundation

/// Aggregates weekly patterns into a `WeeklyInsight`.
/// Extracted from `InsightGenerationService` to keep each file under 300 lines.
enum WeeklyInsightGenerator {
    static func generate(
        snapshots: [DailySmileySnapshot],
        patterns: [InsightPattern],
        patternAnalyzer _: PatternAnalyzer,
        dailyInsights: [DailyInsight] = []
    ) -> WeeklyInsight? {
        guard snapshots.count >= 3 else { return nil }

        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else { return nil }

        let (summaryText, wins, improvements) = Self.generateWeeklySummary(
            from: snapshots,
            patterns: patterns
        )

        return WeeklyInsight(
            weekStartDate: weekStart,
            weekEndDate: today,
            summaryText: summaryText,
            topPatterns: Array(patterns.prefix(3)),
            dailyInsights: dailyInsights,
            improvementAreas: improvements,
            wins: wins
        )
    }
}

// MARK: - Private

private extension WeeklyInsightGenerator {
    // swiftlint:disable:next cyclomatic_complexity
    static func generateWeeklySummary(
        from snapshots: [DailySmileySnapshot],
        patterns: [InsightPattern]
    ) -> (summary: String, wins: [String], improvements: [String]) {
        var wins: [String] = []
        var improvements: [String] = []

        let avgHealthScore = snapshots.map(\.averageHealthScore).reduce(0, +) / Double(snapshots.count)
        let daysLogged = snapshots.count
        let hasGoodSleep = snapshots.contains {
            $0.reflection?.sleepQuality == .great || $0.reflection?.sleepQuality == .good
        }
        let hasMindCheck = snapshots.contains { $0.hasMorningMindCheck || $0.hasEveningMindCheck }

        if daysLogged >= 5 { wins.append("\(daysLogged) days of consistent logging") }
        if avgHealthScore > 0.7 { wins.append("Healthy eating choices") }
        if hasGoodSleep { wins.append("Quality sleep achieved") }
        if hasMindCheck { wins.append("Mindful reflection practice") }

        if avgHealthScore < 0.5 { improvements.append("Consider healthier meal choices") }
        if let top = patterns.first, top.type == .foodSleep {
            improvements.append("Watch meal timing for better sleep")
        }
        if !hasMindCheck { improvements.append("Try morning/evening mind checks") }

        let summary = if wins.count > improvements.count {
            "Great week! You maintained healthy habits with \(daysLogged) days of logging. Keep up the momentum!"
        } else if wins.isEmpty {
            "This week had room for improvement. Focus on consistency and healthier choices next week."
        } else {
            "A balanced week with some wins and areas to work on. Your \(wins.first ?? "effort") is paying off!"
        }

        return (summary, wins, improvements)
    }
}
