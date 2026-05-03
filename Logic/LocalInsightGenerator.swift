import Foundation

/// Pure local insight and weekly summary generation logic.
/// Separated from `InsightGenerationService` to respect the 300-line file limit.
enum LocalInsightGenerator {
    static func generateRichInsight(
        from snapshots: [DailySmileySnapshot],
        patterns: [InsightPattern]
    ) -> (text: String, type: InsightType, references: [InsightReference], confidence: Double) {
        if let topPattern = patterns.first, topPattern.confidence >= BriefingThresholds.confidenceThreshold {
            let text = self.formatPatternAsInsight(topPattern)
            return (text, topPattern.type, topPattern.references, topPattern.confidence)
        }
        let (text, type) = self.generateLocalInsight(from: snapshots)
        return (text, type, [], 0.5)
    }

    static func generateWeeklySummary(
        from snapshots: [DailySmileySnapshot],
        patterns: [InsightPattern]
    ) -> (summary: String, wins: [String], improvements: [String]) {
        var wins: [String] = []
        var improvements: [String] = []

        let avgHealthScore = snapshots.map(\.averageHealthScore).average() ?? ScoringThresholds.neutral
        let daysLogged = snapshots.count
        let hasGoodSleep = snapshots.contains {
            $0.reflection?.sleepQuality == .great || $0.reflection?.sleepQuality == .good
        }
        let hasMindCheck = snapshots.contains { $0.hasMorningMindCheck || $0.hasEveningMindCheck }

        if daysLogged >= ScoringThresholds.minimumConsistentDays {
            wins.append("\(daysLogged) days of consistent logging")
        }
        if avgHealthScore > ScoringThresholds.high { wins.append("Healthy eating choices") }
        if hasGoodSleep { wins.append("Quality sleep achieved") }
        if hasMindCheck { wins.append("Mindful reflection practice") }
        if avgHealthScore < ScoringThresholds.neutral { improvements.append("Consider healthier meal choices") }
        if let topPattern = patterns.first, topPattern.type == .foodSleep {
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

    // MARK: - Private helpers

    private static func formatPatternAsInsight(_ pattern: InsightPattern) -> String {
        var parts: [String] = []
        if !pattern.references.isEmpty {
            let refs = pattern.references.prefix(2).map { "On \($0.formattedDate), \($0.description.lowercased())" }
            parts.append(contentsOf: refs)
        }
        parts.append(pattern.description)
        let advice = self.prescriptiveAdvice(for: pattern.type)
        if !advice.isEmpty { parts.append(advice) }
        return parts.joined(separator: ". ") + "."
    }

    private static func prescriptiveAdvice(for type: InsightType) -> String {
        switch type {
        case .foodSleep: "Consider finishing dinner earlier for better sleep"
        case .mindsetFeeling: "Keep setting intentions - it seems to help your mood"
        case .pattern: "Your consistency is paying off"
        case .encouragement: "Keep up the great work"
        }
    }

    private static func generateLocalInsight(from snapshots: [DailySmileySnapshot]) -> (String, InsightType) {
        guard snapshots.first != nil else {
            return ("Keep logging your meals and sleep to discover patterns in your wellbeing.", .encouragement)
        }
        let avgScore = snapshots.map(\.averageHealthScore).average() ?? ScoringThresholds.neutral
        let insightType = self.determineInsightType(from: snapshots)
        let text = if avgScore > ScoringThresholds.high {
            "Great job! Your healthy eating choices over the past week are likely contributing to better energy and sleep. Keep it up!"
        } else if avgScore > ScoringThresholds.neutral {
            "You're on the right track. Try adding more vegetables to your evening meals - they may help improve your sleep quality."
        } else {
            "Consider lighter, more balanced meals - heavy or processed foods late in the day can affect how you feel the next morning."
        }
        return (text, insightType)
    }

    private static func determineInsightType(from snapshots: [DailySmileySnapshot]) -> InsightType {
        let hasSleepData = snapshots.contains { $0.reflection?.sleepQuality != nil }
        let hasMindCheckData = snapshots.contains { $0.hasMorningMindCheck || $0.hasEveningMindCheck }
        let hasFeelingData = snapshots.contains { $0.reflection?.feeling != nil }
        if hasSleepData, snapshots.count >= 3 { return .foodSleep }
        if hasMindCheckData, hasFeelingData { return .mindsetFeeling }
        if snapshots.count >= 5 { return .pattern }
        return .encouragement
    }
}
