import Foundation

/// Contains detailed computation logic for all pattern analysis algorithms.
/// Extracted from `PatternAnalyzer` to keep `PatternAnalyzer.swift` under 200 lines.
///
/// Each method analyses a single correlation type from daily snapshots and returns
/// either `[InsightPattern]` (for the legacy DailyInsight pipeline) or `[CorrelationCard]`
/// (for the DailyBriefing cards pipeline). Both types are intentionally separate until
/// the insight pipeline is consolidated.
final class PatternAnalysisEngine {
    // MARK: - Legacy Insight Pipeline

    func analyzePatterns(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        guard snapshots.count >= BriefingThresholds.minimumDataPoints else { return [] }

        var patterns: [InsightPattern] = []
        patterns.append(contentsOf: self.analyzeFoodSleepCorrelation(from: snapshots))
        patterns.append(contentsOf: self.analyzeTodoMoodCorrelation(from: snapshots))
        patterns.append(contentsOf: self.analyzeGratitudePractice(from: snapshots))
        patterns.append(contentsOf: self.analyzeMealTimingPatterns(from: snapshots))
        return patterns.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Briefing Cards Pipeline

    func generateCorrelationCards(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        guard snapshots.count >= BriefingThresholds.minimumDataPoints else { return [] }

        var cards: [CorrelationCard] = []
        cards.append(contentsOf: self.analyzeFoodToFeeling(from: snapshots))
        cards.append(contentsOf: self.analyzeTimingConsistency(from: snapshots))
        cards.append(contentsOf: self.analyzeTodoProductivity(from: snapshots))
        cards.append(contentsOf: self.analyzeFoodDebt(from: snapshots))
        return cards.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Food-Sleep Correlation

    func analyzeFoodSleepCorrelation(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        var patterns: [InsightPattern] = []

        let lateDinnerDays = self.findLateDinnerDays(from: snapshots)
        let poorSleepDays = self.findPoorSleepDays(from: snapshots)

        let overlappingDays = lateDinnerDays.filter { lateDinner in
            let calendar = Calendar.current
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: lateDinner.date) else { return false }
            return poorSleepDays.contains { calendar.isDate($0.date, inSameDayAs: nextDay) }
        }

        guard !overlappingDays.isEmpty else { return patterns }
        let confidence = Double(overlappingDays.count) / Double(max(lateDinnerDays.count, 1))
        guard confidence >= BriefingThresholds.confidenceThreshold else { return patterns }

        let references = overlappingDays.map { day -> InsightReference in
            let lateMeal = day.meals.first { self.isLateDinner($0) }
            let mealDescription = lateMeal
                .map { "Late \($0.mealType.rawValue) at \(self.formatTime($0.timestamp))" }
                ?? "Late dinner"
            return InsightReference(date: day.date, description: mealDescription, category: .food)
        }

        patterns.append(InsightPattern(
            type: .foodSleep,
            description: "Late dinners may be affecting your sleep quality",
            confidence: confidence,
            references: references
        ))
        return patterns
    }

    // MARK: - Todo-Mood Correlation

    func analyzeTodoMoodCorrelation(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        var patterns: [InsightPattern] = []

        let completedTodoDays = snapshots.filter { snapshot in
            guard let todos = snapshot.morningMindCheck?.filter({ $0.category == .todo }) else { return false }
            return todos.contains { $0.isAccomplished == true }
        }
        let goodMoodDays = snapshots.filter { $0.reflection?.feeling == .great || $0.reflection?.feeling == .calm }

        let calendar = Calendar.current
        let overlappingDays = completedTodoDays.filter { completed in
            goodMoodDays.contains { calendar.isDate($0.date, inSameDayAs: completed.date) }
        }

        guard overlappingDays.count >= 2 else { return patterns }
        let confidence = Double(overlappingDays.count) / Double(max(completedTodoDays.count, 1))
        guard confidence >= BriefingThresholds.confidenceThreshold else { return patterns }

        let references = overlappingDays.prefix(BriefingThresholds.maximumInsightReferences)
            .map { day -> InsightReference in
                let completedCount = day.morningMindCheck?
                    .count(where: { $0.category == .todo && $0.isAccomplished == true }) ?? 0
                return InsightReference(
                    date: day.date,
                    description: "\(completedCount) todo\(completedCount == 1 ? "" : "s") completed",
                    category: .todo
                )
            }

        patterns.append(InsightPattern(
            type: .mindsetFeeling,
            description: "Completing your todos correlates with better mood",
            confidence: confidence,
            references: Array(references)
        ))
        return patterns
    }

    // MARK: - Gratitude Practice

    func analyzeGratitudePractice(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        var patterns: [InsightPattern] = []

        let gratitudeDays = snapshots.filter { snapshot in
            let hasGratitude = snapshot.morningMindCheck?.contains { $0.category == .gratitude } ?? false
            let hasGratefulFor = snapshot.eveningMindCheck?.contains { $0.category == .gratefulFor } ?? false
            return hasGratitude || hasGratefulFor
        }
        let goodOutcomeDays = snapshots.filter { snapshot in
            let goodFeeling = snapshot.reflection?.feeling == .great || snapshot.reflection?.feeling == .calm
            let goodSleep = snapshot.reflection?.sleepQuality == .great || snapshot.reflection?.sleepQuality == .good
            return goodFeeling || goodSleep
        }

        let overlappingDays = gratitudeDays.filter { gratitude in
            goodOutcomeDays.contains { Calendar.current.isDate($0.date, inSameDayAs: gratitude.date) }
        }

        guard overlappingDays.count >= 2, gratitudeDays.count >= 2 else { return patterns }
        let confidence = Double(overlappingDays.count) / Double(gratitudeDays.count)
        guard confidence >= BriefingThresholds.confidenceThreshold else { return patterns }

        let references = overlappingDays.prefix(BriefingThresholds.maximumInsightReferences)
            .map { InsightReference(date: $0.date, description: "Gratitude practiced", category: .feeling) }

        patterns.append(InsightPattern(
            type: .pattern,
            description: "Days with gratitude practice tend to have better outcomes",
            confidence: confidence,
            references: Array(references)
        ))
        return patterns
    }

    // MARK: - Meal Timing Patterns

    func analyzeMealTimingPatterns(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        var patterns: [InsightPattern] = []
        var mealTimings: [(date: Date, averageHour: Double)] = []

        for snapshot in snapshots where !snapshot.meals.isEmpty {
            let hours = snapshot.meals.map { Calendar.current.component(.hour, from: $0.timestamp) }
            let avgHour = Double(hours.reduce(0, +)) / Double(hours.count)
            mealTimings.append((snapshot.date, avgHour))
        }

        let earlyEatingDays = mealTimings.filter { $0.averageHour < 18 }
        let goodSleepDays = self.findGoodSleepDays(from: snapshots)

        let overlappingEarly = earlyEatingDays.filter { early in
            let calendar = Calendar.current
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: early.date) else { return false }
            return goodSleepDays.contains { calendar.isDate($0.date, inSameDayAs: nextDay) }
        }

        guard overlappingEarly.count >= 2 else { return patterns }
        let confidence = Double(overlappingEarly.count) / Double(max(earlyEatingDays.count, 1))
        guard confidence >= BriefingThresholds.confidenceThreshold else { return patterns }

        let references = overlappingEarly.prefix(BriefingThresholds.maximumInsightReferences)
            .map { InsightReference(date: $0.date, description: "Finished eating early", category: .food) }

        patterns.append(InsightPattern(
            type: .foodSleep,
            description: "Eating earlier in the day may improve your sleep",
            confidence: confidence,
            references: Array(references)
        ))
        return patterns
    }

    // MARK: - Food Debt

    func analyzeFoodDebt(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let recent = Array(
            snapshots
                .sorted { $0.date > $1.date }
                .filter { $0.mealCount > 0 }
                .prefix(2)
        )
        guard recent.count == 2 else { return [] }

        let daysBetween = Calendar.current.dateComponents(
            [.day], from: recent[1].date, to: recent[0].date
        ).day ?? Int.max
        guard daysBetween == 1,
              recent.allSatisfy({ $0.averageHealthScore < ScoringThresholds.foodDebtBadDay })
        else { return [] }

        let avgScore = recent.map(\.averageHealthScore).average() ?? ScoringThresholds.neutral
        let confidence = max(0.0, min(1.0, (ScoringThresholds.foodDebtBadDay - avgScore) * 5.0))
        let refs = recent.map {
            InsightReference(date: $0.date, description: "Low-quality eating day", category: .food)
        }
        return [CorrelationCard(
            category: .foodDebt,
            observation: "2 days of low-quality eating — inflammation and cravings may be elevated today",
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
            observation: "Days with healthier meals tend to end with a better mood",
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
            observation: "Regular meal timing is linked to better sleep quality",
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
            observation: "Higher task completion days correlate with healthier food choices",
            confidence: confidence,
            dataPoints: Array(refs)
        )]
    }

    // MARK: - Helpers

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
