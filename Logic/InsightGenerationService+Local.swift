import Foundation

struct RichInsightResult {
    let text: String
    let type: InsightType
    let references: [InsightReference]
    let confidence: Double
}

extension InsightGenerationService {
    func generateRichInsight(
        from snapshots: [DailySmileySnapshot],
        patterns: [InsightPattern]
    ) -> RichInsightResult {
        // If we have high-confidence patterns, use them
        if let topPattern = patterns.first, topPattern.confidence >= 0.6 {
            let text = self.formatPatternAsInsight(topPattern)
            return RichInsightResult(
                text: text,
                type: topPattern.type,
                references: topPattern.references,
                confidence: topPattern.confidence
            )
        }

        // Otherwise, generate a generic insight based on data
        let (text, type) = self.generateLocalInsight(from: snapshots)
        return RichInsightResult(text: text, type: type, references: [], confidence: 0.5)
    }

    func formatPatternAsInsight(_ pattern: InsightPattern) -> String {
        var parts: [String] = []

        // Add observational part with date references
        if !pattern.references.isEmpty {
            let refStrings = pattern.references.prefix(2).map { ref in
                "On \(ref.formattedDate), \(ref.description.lowercased())"
            }
            parts.append(contentsOf: refStrings)
        }

        // Add the pattern description
        parts.append(pattern.description)

        // Add prescriptive advice based on pattern type
        let advice = self.getPrescriptiveAdvice(for: pattern.type)
        if !advice.isEmpty {
            parts.append(advice)
        }

        return parts.joined(separator: ". ") + "."
    }

    func getPrescriptiveAdvice(for type: InsightType) -> String {
        switch type {
        case .foodSleep:
            "Consider finishing dinner earlier for better sleep"
        case .mindsetFeeling:
            "Keep setting intentions - it seems to help your mood"
        case .pattern:
            "Your consistency is paying off"
        case .encouragement:
            "Keep up the great work"
        case .intentAlignment:
            "Setting a daily intention helps you eat more mindfully"
        case .focusFood:
            "Notice how lighter meals support sustained focus"
        }
    }

    func generateLocalInsight(from snapshots: [DailySmileySnapshot]) -> (String, InsightType) {
        // Simple local insight generation (fallback when no patterns detected)
        guard snapshots.first != nil else {
            return ("Keep logging your meals and sleep to discover patterns in your wellbeing.", .encouragement)
        }

        let avgScore = snapshots.map(\.averageHealthScore).reduce(0, +) / Double(snapshots.count)
        let insightType = self.determineInsightType(from: snapshots)

        // swiftlint:disable line_length
        let text = if avgScore > 0.7 {
            "Great job! Your healthy eating choices over the past week are likely contributing to better energy and sleep. Keep it up!"
        } else if avgScore > 0.5 {
            "You're on the right track. Try adding more vegetables to your evening meals - they may help improve your sleep quality."
        } else {
            "Consider lighter, more balanced meals - heavy or processed foods late in the day can affect how you feel the next morning."
        }
        // swiftlint:enable line_length

        return (text, insightType)
    }

    func determineInsightType(from snapshots: [DailySmileySnapshot]) -> InsightType {
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
