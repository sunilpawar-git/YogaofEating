import Foundation

// MARK: - Local Briefing Fallback

extension BriefingService {
    func generateLocalBriefing(
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

    func computeAverageSleepQuality(from snapshots: [DailySmileySnapshot]) -> Double {
        let sleepScores: [Double] = snapshots.compactMap { snap -> Double? in
            snap.reflection?.sleepQuality?.synthesisScore
        }
        guard !sleepScores.isEmpty else { return 0.5 }
        return sleepScores.reduce(0, +) / Double(sleepScores.count)
    }

    func computeTrendDirection(from snapshots: [DailySmileySnapshot]) -> TrendDirection {
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
