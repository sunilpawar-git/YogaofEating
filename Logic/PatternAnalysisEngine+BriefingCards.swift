import Foundation

/// Briefing-card correlation algorithms for `PatternAnalysisEngine`.
/// Extracted to keep `PatternAnalysisEngine.swift` under the 250-line limit.
/// All methods return `[CorrelationCard]` for use in the `DailyBriefing` pipeline.
extension PatternAnalysisEngine {
    // MARK: - Food Debt

    /// Mirrors the calendar-based definition in `HistoricalDataService.foodDebtStartingState`:
    /// food debt is triggered by two *specific* prior calendar days (yesterday and day-before-yesterday)
    /// both having low scores, not merely the two most-recent logged days being consecutive.
    /// This alignment ensures the correlation card and the smiley starting state agree.
    func analyzeFoodDebt(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let calendar = Calendar.current
        let today = snapshots.map(\.date).max() ?? Date()
        guard
            let d1 = calendar.date(byAdding: .day, value: -1, to: today),
            let d2 = calendar.date(byAdding: .day, value: -2, to: today)
        else { return [] }

        guard let s1 = snapshots.first(where: { calendar.isDate($0.date, inSameDayAs: d1) }),
              s1.mealCount > 0,
              let s2 = snapshots.first(where: { calendar.isDate($0.date, inSameDayAs: d2) }),
              s2.mealCount > 0
        else { return [] }

        let recent = [s1, s2]
        guard recent.allSatisfy({ $0.averageHealthScore < ScoringThresholds.foodDebtBadDay })
        else { return [] }

        let avgScore = recent.map(\.averageHealthScore).average() ?? ScoringThresholds.neutral
        let confidence = max(0.0, min(1.0, (ScoringThresholds.foodDebtBadDay - avgScore) * 5.0))
        let refs = recent.map {
            InsightReference(date: $0.date, description: "Low-quality eating day", category: .food)
        }
        return [CorrelationCard(
            category: .foodDebt,
            observation: Strings.Insight.Cards.foodDebt,
            confidence: confidence,
            dataPoints: Array(refs)
        )]
    }

    // MARK: - Food-to-Feeling

    func analyzeFoodToFeeling(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let paired: [(score: Double, isGoodMood: Bool)] = snapshots.compactMap { snap in
            guard !snap.meals.isEmpty, let feeling = snap.reflection?.feeling else { return nil }
            let avgScore = snap.meals.map(\.healthScore).average() ?? ScoringThresholds.neutral
            return (avgScore, feeling == .great || feeling == .calm)
        }

        guard paired.count >= BriefingThresholds.minimumDataPoints else { return [] }

        let goodDays = paired.filter(\.isGoodMood)
        let badDays = paired.filter { !$0.isGoodMood }
        guard !goodDays.isEmpty, !badDays.isEmpty else { return [] }

        let gap = (goodDays.map(\.score).average() ?? ScoringThresholds.neutral)
            - (badDays.map(\.score).average() ?? ScoringThresholds.neutral)
        guard gap > BriefingThresholds.scoreDifferenceSignificant else { return [] }

        let confidence = min(1.0, gap * 2.0)
        guard confidence >= BriefingThresholds.confidenceThreshold else { return [] }

        let references = snapshots
            .filter { !$0.meals.isEmpty && ($0.reflection?.feeling == .great || $0.reflection?.feeling == .calm) }
            .prefix(BriefingThresholds.maximumInsightReferences)
            .map { InsightReference(date: $0.date, description: "Healthy meals on this day", category: .food) }

        return [CorrelationCard(
            category: .foodToMood,
            observation: Strings.Insight.Cards.foodToMood,
            confidence: confidence,
            dataPoints: Array(references)
        )]
    }

    // MARK: - Timing Consistency

    func analyzeTimingConsistency(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let calendar = Calendar.current

        let timed: [(date: Date, stdDev: Double)] = snapshots.compactMap { snap in
            guard snap.meals.count >= 2 else { return nil }
            let hours = snap.meals.map { Double(calendar.component(.hour, from: $0.timestamp)) }
            let mean = hours.reduce(0, +) / Double(hours.count)
            let variance = hours.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(hours.count)
            return (snap.date, variance.squareRoot())
        }

        guard timed.count >= BriefingThresholds.minimumDataPoints else { return [] }

        let consistentDays = timed.filter { $0.stdDev < BriefingThresholds.timingConsistencyStdDev }
        let inconsistentDays = timed.filter { $0.stdDev >= BriefingThresholds.timingConsistencyStdDev }
        guard !consistentDays.isEmpty, !inconsistentDays.isEmpty else { return [] }

        let consistentGoodSleep = consistentDays.filter { day in
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day.date) else { return false }
            return snapshots.contains { snap in
                calendar.isDate(snap.date, inSameDayAs: nextDay)
                    && (snap.reflection?.sleepQuality == .great || snap.reflection?.sleepQuality == .good)
            }
        }

        let ratio = Double(consistentGoodSleep.count) / Double(consistentDays.count)
        guard ratio >= BriefingThresholds.confidenceThreshold else { return [] }

        let refs = consistentGoodSleep.prefix(BriefingThresholds.maximumInsightReferences)
            .map { InsightReference(date: $0.date, description: "Consistent meal timing", category: .food) }

        return [CorrelationCard(
            category: .timingPattern,
            observation: Strings.Insight.Cards.timingPattern,
            confidence: ratio,
            dataPoints: Array(refs)
        )]
    }

    // MARK: - Todo Productivity

    func analyzeTodoProductivity(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let paired: [(completionRate: Double, avgFoodScore: Double)] = snapshots.compactMap { snap in
            guard let todos = snap.morningMindCheck?.filter({ $0.category == .todo }),
                  !todos.isEmpty, !snap.meals.isEmpty else { return nil }
            let completed = Double(todos.count(where: { $0.isAccomplished == true }))
            let rate = completed / Double(todos.count)
            let avgScore = snap.meals.map(\.healthScore).average() ?? ScoringThresholds.neutral
            return (rate, avgScore)
        }

        guard paired.count >= BriefingThresholds.minimumDataPoints else { return [] }

        let productive = paired.filter { $0.completionRate > 0.5 }
        let unproductive = paired.filter { $0.completionRate <= 0.5 }
        guard !productive.isEmpty, !unproductive.isEmpty else { return [] }

        let gap = (productive.map(\.avgFoodScore).average() ?? ScoringThresholds.neutral)
            - (unproductive.map(\.avgFoodScore).average() ?? ScoringThresholds.neutral)
        guard gap > BriefingThresholds.minimumScoreDelta else { return [] }

        let confidence = min(1.0, gap * 2.5)
        guard confidence >= BriefingThresholds.confidenceThreshold else { return [] }

        let refs = snapshots
            .filter { snap in
                guard let todos = snap.morningMindCheck?.filter({ $0.category == .todo }),
                      !todos.isEmpty else { return false }
                return Double(todos.count(where: { $0.isAccomplished == true })) / Double(todos.count) > 0.5
            }
            .prefix(BriefingThresholds.maximumInsightReferences)
            .map { InsightReference(date: $0.date, description: "Productive day with healthy meals", category: .todo) }

        return [CorrelationCard(
            category: .focusToFeeling,
            observation: Strings.Insight.Cards.todoProductivity,
            confidence: confidence,
            dataPoints: Array(refs)
        )]
    }
}
