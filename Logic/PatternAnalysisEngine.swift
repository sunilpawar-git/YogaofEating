import Foundation

/// Named thresholds for pattern correlation analysis (SSOT for pattern analysis constants).
enum BriefingThresholds {
    static let timingConsistencyStdDev: Double = 5.5
    static let scoreDifferenceSignificant: Double = 0.15
    static let minimumScoreDelta: Double = 0.1
    static let minimumDataPoints: Int = 3
    static let confidenceThreshold: Double = 0.6
    static let lateDinnerHour: Int = 21
    static let maximumInsightReferences: Int = 3
    static let minimumTodosForFollowthrough: Int = 2
    static let lowFollowthroughRate: Double = 0.3
    static let sleepMismatchClarityThreshold: Double = 0.45
    static let carryOverLoadDays: Int = 3
    static let carryOverLowThreshold: Double = 0.45
}

/// Computes correlation pattern analysis from daily snapshots.
/// Produces `[CorrelationCard]` for the unified `DailyInsight` pipeline.
final class PatternAnalysisEngine {
    // MARK: - Briefing Cards Pipeline

    func generateCorrelationCards(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        guard snapshots.count >= BriefingThresholds.minimumDataPoints else { return [] }

        var cards: [CorrelationCard] = []
        cards.append(contentsOf: self.analyzeFoodToFeeling(from: snapshots))
        cards.append(contentsOf: self.analyzeTimingConsistency(from: snapshots))
        cards.append(contentsOf: self.analyzeTodoProductivity(from: snapshots))
        cards.append(contentsOf: self.analyzeFoodDebt(from: snapshots))
        cards.append(contentsOf: self.analyzeSleepRecoveryCarryover(from: snapshots))
        cards.append(contentsOf: self.analyzeIntentionFollowthrough(from: snapshots))
        cards.append(contentsOf: self.analyzeJournalTonePrediction(from: snapshots))
        cards.append(contentsOf: self.analyzeSleepMismatch(from: snapshots))
        cards.append(contentsOf: self.analyzeCarryOverLoad(from: snapshots))
        return cards.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Helpers (shared by sub-analyzers)

    func findLateDinnerDays(from snapshots: [DailySmileySnapshot]) -> [DailySmileySnapshot] {
        snapshots.filter { $0.meals.contains { self.isLateDinner($0) } }
    }

    func isLateDinner(_ meal: Meal) -> Bool {
        Calendar.current.component(.hour, from: meal.timestamp) >= BriefingThresholds.lateDinnerHour
    }

    func findPoorSleepDays(from snapshots: [DailySmileySnapshot]) -> [DailySmileySnapshot] {
        snapshots.filter {
            $0.reflection?.sleepQuality == .poor || $0.reflection?.sleepQuality == .terrible
        }
    }

    func findGoodSleepDays(from snapshots: [DailySmileySnapshot]) -> [DailySmileySnapshot] {
        snapshots.filter {
            $0.reflection?.sleepQuality == .great || $0.reflection?.sleepQuality == .good
        }
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
