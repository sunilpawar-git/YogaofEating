import Foundation

/// Named thresholds for briefing correlation analysis (SSOT for PatternAnalyzer magic numbers).
enum BriefingThresholds {
    static let timingConsistencyStdDev: Double = 5.5
    static let scoreDifferenceSignificant: Double = 0.15
    static let minimumScoreDelta: Double = 0.1
}

/// Analyzes user data to detect patterns between food, sleep, todos, and mood.
/// Used by InsightGenerationService to create rich, date-referenced insights.
class PatternAnalyzer {
    // MARK: - Configuration

    /// Minimum number of data points required to detect patterns
    private let minimumDataPoints = 3

    /// Hour after which dinner is considered "late" (9 PM)
    private let lateDinnerHour = 21

    /// Confidence threshold for pattern detection
    private let confidenceThreshold = 0.6

    // MARK: - Main Analysis

    /// Analyzes all available patterns from the given snapshots.
    // MARK: - Legacy Insight Pipeline

    // `analyzePatterns` feeds the legacy `DailyInsight` text pipeline.
    // `generateCorrelationCards` (below) feeds the new `DailyBriefing` cards pipeline.
    // They are intentionally separate until the insight pipeline is consolidated.

    /// - Parameter snapshots: Historical daily snapshots to analyze
    /// - Returns: Array of detected patterns, sorted by confidence
    func analyzePatterns(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        guard snapshots.count >= self.minimumDataPoints else {
            return []
        }

        var patterns: [InsightPattern] = []

        // Analyze different correlation types
        patterns.append(contentsOf: self.analyzeFoodSleepCorrelation(from: snapshots))
        patterns.append(contentsOf: self.analyzeTodoMoodCorrelation(from: snapshots))
        patterns.append(contentsOf: self.analyzeGratitudePractice(from: snapshots))
        patterns.append(contentsOf: self.analyzeMealTimingPatterns(from: snapshots))

        // Sort by confidence and return
        return patterns.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Food-Sleep Correlation

    /// Analyzes correlation between late dinners and poor sleep.
    /// - Parameter snapshots: Historical daily snapshots
    /// - Returns: Detected food-sleep patterns
    func analyzeFoodSleepCorrelation(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        var patterns: [InsightPattern] = []

        // Look for late dinner -> poor sleep correlation
        let lateDinnerDays = self.findLateDinnerDays(from: snapshots)
        let poorSleepDays = self.findPoorSleepDays(from: snapshots)

        // Check overlap
        let overlappingDays = lateDinnerDays.filter { lateDinner in
            let calendar = Calendar.current
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: lateDinner.date) else { return false }
            return poorSleepDays.contains { calendar.isDate($0.date, inSameDayAs: nextDay) }
        }

        if !overlappingDays.isEmpty {
            let confidence = Double(overlappingDays.count) / Double(max(lateDinnerDays.count, 1))

            if confidence >= self.confidenceThreshold {
                let references = overlappingDays.map { day -> InsightReference in
                    let lateMeal = day.meals.first { self.isLateDinner($0) }
                    let mealDescription = lateMeal
                        .map { "Late \($0.mealType.rawValue) at \(self.formatTime($0.timestamp))" }
                        ?? "Late dinner"

                    return InsightReference(
                        date: day.date,
                        description: mealDescription,
                        category: .food
                    )
                }

                patterns.append(
                    InsightPattern(
                        type: .foodSleep,
                        description: "Late dinners may be affecting your sleep quality",
                        confidence: confidence,
                        references: references
                    )
                )
            }
        }

        return patterns
    }

    // MARK: - Todo-Mood Correlation

    /// Analyzes correlation between todo completion and mood.
    /// - Parameter snapshots: Historical daily snapshots
    /// - Returns: Detected mindset-feeling patterns
    func analyzeTodoMoodCorrelation(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        var patterns: [InsightPattern] = []

        // Days with completed todos
        let completedTodoDays = snapshots.filter { snapshot in
            guard let todos = snapshot.morningMindCheck?.filter({ $0.category == .todo }) else { return false }
            return todos.contains { $0.isAccomplished == true }
        }

        // Days with good mood
        let goodMoodDays = snapshots.filter { snapshot in
            guard let feeling = snapshot.reflection?.feeling else { return false }
            return feeling == .great || feeling == .calm
        }

        // Check overlap
        let calendar = Calendar.current
        let overlappingDays = completedTodoDays.filter { completed in
            goodMoodDays.contains { calendar.isDate($0.date, inSameDayAs: completed.date) }
        }

        if overlappingDays.count >= 2 {
            let confidence = Double(overlappingDays.count) / Double(max(completedTodoDays.count, 1))

            if confidence >= self.confidenceThreshold {
                let references = overlappingDays.prefix(3).map { day -> InsightReference in
                    let completedCount = day.morningMindCheck?
                        .count(where: { $0.category == .todo && $0.isAccomplished == true })
                        ?? 0

                    return InsightReference(
                        date: day.date,
                        description: "\(completedCount) todo\(completedCount == 1 ? "" : "s") completed",
                        category: .todo
                    )
                }

                patterns.append(
                    InsightPattern(
                        type: .mindsetFeeling,
                        description: "Completing your todos correlates with better mood",
                        confidence: confidence,
                        references: Array(references)
                    )
                )
            }
        }

        return patterns
    }

    // MARK: - Gratitude Practice

    /// Analyzes correlation between gratitude practice and wellbeing.
    /// - Parameter snapshots: Historical daily snapshots
    /// - Returns: Detected gratitude patterns
    func analyzeGratitudePractice(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        var patterns: [InsightPattern] = []

        // Days with gratitude entries
        let gratitudeDays = snapshots.filter { snapshot in
            let hasGratitude = snapshot.morningMindCheck?.contains { $0.category == .gratitude } ?? false
            let hasGratefulFor = snapshot.eveningMindCheck?.contains { $0.category == .gratefulFor } ?? false
            return hasGratitude || hasGratefulFor
        }

        // Days with good outcomes
        let goodOutcomeDays = snapshots.filter { snapshot in
            let goodFeeling = snapshot.reflection?.feeling == .great || snapshot.reflection?.feeling == .calm
            let goodSleep = snapshot.reflection?.sleepQuality == .great || snapshot.reflection?.sleepQuality == .good
            return goodFeeling || goodSleep
        }

        // Check overlap
        let overlappingDays = gratitudeDays.filter { gratitude in
            goodOutcomeDays.contains { Calendar.current.isDate($0.date, inSameDayAs: gratitude.date) }
        }

        if overlappingDays.count >= 2, gratitudeDays.count >= 2 {
            let confidence = Double(overlappingDays.count) / Double(gratitudeDays.count)

            if confidence >= self.confidenceThreshold {
                let references = overlappingDays.prefix(3).map { day -> InsightReference in
                    InsightReference(
                        date: day.date,
                        description: "Gratitude practiced",
                        category: .feeling
                    )
                }

                patterns.append(
                    InsightPattern(
                        type: .pattern,
                        description: "Days with gratitude practice tend to have better outcomes",
                        confidence: confidence,
                        references: Array(references)
                    )
                )
            }
        }

        return patterns
    }

    // MARK: - Meal Timing Patterns

    /// Analyzes meal timing patterns and their effects.
    /// - Parameter snapshots: Historical daily snapshots
    /// - Returns: Detected meal timing patterns
    func analyzeMealTimingPatterns(from snapshots: [DailySmileySnapshot]) -> [InsightPattern] {
        var patterns: [InsightPattern] = []

        // Analyze average meal timing
        var mealTimings: [(date: Date, averageHour: Double)] = []

        for snapshot in snapshots where !snapshot.meals.isEmpty {
            let hours = snapshot.meals.map { Calendar.current.component(.hour, from: $0.timestamp) }
            let avgHour = Double(hours.reduce(0, +)) / Double(hours.count)
            mealTimings.append((snapshot.date, avgHour))
        }

        // Check for consistent early eating -> good sleep pattern
        let earlyEatingDays = mealTimings.filter { $0.averageHour < 18 }
        let goodSleepDays = self.findGoodSleepDays(from: snapshots)

        let overlappingEarly = earlyEatingDays.filter { early in
            let calendar = Calendar.current
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: early.date) else { return false }
            return goodSleepDays.contains { calendar.isDate($0.date, inSameDayAs: nextDay) }
        }

        if overlappingEarly.count >= 2 {
            let confidence = Double(overlappingEarly.count) / Double(max(earlyEatingDays.count, 1))

            if confidence >= self.confidenceThreshold {
                let references = overlappingEarly.prefix(3).map { day -> InsightReference in
                    InsightReference(
                        date: day.date,
                        description: "Finished eating early",
                        category: .food
                    )
                }

                patterns.append(
                    InsightPattern(
                        type: .foodSleep,
                        description: "Eating earlier in the day may improve your sleep",
                        confidence: confidence,
                        references: Array(references)
                    )
                )
            }
        }

        return patterns
    }

    // MARK: - Correlation Card Generation

    // MARK: - New Briefing Cards Pipeline

    /// Produces CorrelationCards from all analyzers, sorted by confidence descending.
    func generateCorrelationCards(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        guard snapshots.count >= self.minimumDataPoints else { return [] }

        var cards: [CorrelationCard] = []
        cards.append(contentsOf: self.analyzeFoodToFeeling(from: snapshots))
        cards.append(contentsOf: self.analyzeTimingConsistency(from: snapshots))
        cards.append(contentsOf: self.analyzeTodoProductivity(from: snapshots))
        cards.append(contentsOf: self.analyzeFoodDebt(from: snapshots))

        return cards.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Food Debt

    /// Detects 2 consecutive recent days with poor average food scores and generates a
    /// CorrelationCard warning that inflammation and cravings may be elevated today.
    /// Basis: Esposito et al. (2002) — inflammatory markers after consecutive poor-eating days.
    func analyzeFoodDebt(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let recent = Array(
            snapshots
                .sorted { $0.date > $1.date }
                .filter { $0.mealCount > 0 }
                .prefix(2)
        )
        guard recent.count == 2 else { return [] }

        // Require the 2 snapshots to be consecutive calendar days — prevents false positives
        // from sporadic loggers whose most recent 2 entries are weeks apart.
        let daysBetween = Calendar.current.dateComponents(
            [.day], from: recent[1].date, to: recent[0].date
        ).day ?? Int.max
        guard daysBetween == 1,
              recent.allSatisfy({ $0.averageHealthScore < ScoringThresholds.foodDebtBadDay })
        else { return [] }

        let avgScore = recent.map(\.averageHealthScore).reduce(0, +) / 2.0
        let confidence = max(0.0, min(1.0, (ScoringThresholds.foodDebtBadDay - avgScore) * 5.0))
        let refs = recent.map {
            InsightReference(date: $0.date, description: "Low-quality eating day", category: .food)
        }
        return [
            CorrelationCard(
                category: .foodDebt,
                observation: "2 days of low-quality eating — inflammation and cravings may be elevated today",
                confidence: confidence,
                dataPoints: Array(refs)
            )
        ]
    }

    // MARK: - Food-to-Feeling

    /// Correlates average daily meal healthScore with the user's end-of-day feeling.
    func analyzeFoodToFeeling(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let paired: [(score: Double, isGoodMood: Bool)] = snapshots.compactMap { snap in
            guard !snap.meals.isEmpty,
                  let feeling = snap.reflection?.feeling else { return nil }
            let avgScore = snap.meals.map(\.healthScore).reduce(0, +) / Double(snap.meals.count)
            let good = feeling == .great || feeling == .calm
            return (avgScore, good)
        }

        guard paired.count >= self.minimumDataPoints else { return [] }

        let goodDays = paired.filter(\.isGoodMood)
        let badDays = paired.filter { !$0.isGoodMood }

        guard !goodDays.isEmpty, !badDays.isEmpty else { return [] }

        let avgGood = goodDays.map(\.score).reduce(0, +) / Double(goodDays.count)
        let avgBad = badDays.map(\.score).reduce(0, +) / Double(badDays.count)
        let gap = avgGood - avgBad

        guard gap > BriefingThresholds.scoreDifferenceSignificant else { return [] }

        let confidence = min(1.0, gap * 2.0)
        guard confidence >= self.confidenceThreshold else { return [] }

        let references = snapshots
            .filter { !$0.meals.isEmpty && ($0.reflection?.feeling == .great || $0.reflection?.feeling == .calm) }
            .prefix(3)
            .map { InsightReference(date: $0.date, description: "Healthy meals on this day", category: .food) }

        return [
            CorrelationCard(
                category: .foodToMood,
                observation: "Days with healthier meals tend to end with a better mood",
                confidence: confidence,
                dataPoints: Array(references)
            )
        ]
    }

    // MARK: - Timing Consistency

    /// Compares standard-deviation of meal hours with next-day sleep quality.
    func analyzeTimingConsistency(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let calendar = Calendar.current

        let timed: [(date: Date, stdDev: Double)] = snapshots.compactMap { snap in
            guard snap.meals.count >= 2 else { return nil }
            let hours = snap.meals.map { Double(calendar.component(.hour, from: $0.timestamp)) }
            let mean = hours.reduce(0, +) / Double(hours.count)
            let variance = hours.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(hours.count)
            return (snap.date, variance.squareRoot())
        }

        guard timed.count >= self.minimumDataPoints else { return [] }

        let consistentDays = timed.filter { $0.stdDev < BriefingThresholds.timingConsistencyStdDev }
        let inconsistentDays = timed.filter { $0.stdDev >= BriefingThresholds.timingConsistencyStdDev }

        guard !consistentDays.isEmpty, !inconsistentDays.isEmpty else { return [] }

        let consistentGoodSleep = consistentDays.filter { day in
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day.date) else { return false }
            return snapshots.contains { snap in
                calendar.isDate(snap.date, inSameDayAs: nextDay) &&
                    (snap.reflection?.sleepQuality == .great || snap.reflection?.sleepQuality == .good)
            }
        }

        let ratio = Double(consistentGoodSleep.count) / Double(consistentDays.count)
        guard ratio >= self.confidenceThreshold else { return [] }

        let refs = consistentGoodSleep.prefix(3).map {
            InsightReference(date: $0.date, description: "Consistent meal timing", category: .food)
        }

        return [
            CorrelationCard(
                category: .timingPattern,
                observation: "Regular meal timing is linked to better sleep quality",
                confidence: ratio,
                dataPoints: Array(refs)
            )
        ]
    }

    // MARK: - Todo Productivity

    /// Correlates todo completion rate with daily meal quality.
    func analyzeTodoProductivity(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let paired: [(completionRate: Double, avgFoodScore: Double)] = snapshots.compactMap { snap in
            guard let todos = snap.morningMindCheck?.filter({ $0.category == .todo }),
                  !todos.isEmpty,
                  !snap.meals.isEmpty else { return nil }
            let completed = Double(todos.count(where: { $0.isAccomplished == true }))
            let rate = completed / Double(todos.count)
            let avgScore = snap.meals.map(\.healthScore).reduce(0, +) / Double(snap.meals.count)
            return (rate, avgScore)
        }

        guard paired.count >= self.minimumDataPoints else { return [] }

        let productive = paired.filter { $0.completionRate > 0.5 }
        let unproductive = paired.filter { $0.completionRate <= 0.5 }

        guard !productive.isEmpty, !unproductive.isEmpty else { return [] }

        let avgFoodProductive = productive.map(\.avgFoodScore).reduce(0, +) / Double(productive.count)
        let avgFoodUnproductive = unproductive.map(\.avgFoodScore).reduce(0, +) / Double(unproductive.count)
        let gap = avgFoodProductive - avgFoodUnproductive

        guard gap > BriefingThresholds.minimumScoreDelta else { return [] }

        let confidence = min(1.0, gap * 2.5)
        guard confidence >= self.confidenceThreshold else { return [] }

        let refs = snapshots
            .filter { snap in
                guard let todos = snap.morningMindCheck?.filter({ $0.category == .todo }),
                      !todos.isEmpty else { return false }
                return Double(todos.count(where: { $0.isAccomplished == true })) / Double(todos.count) > 0.5
            }
            .prefix(3)
            .map { InsightReference(date: $0.date, description: "Productive day with healthy meals", category: .todo) }

        return [
            CorrelationCard(
                category: .focusToFeeling,
                observation: "Higher task completion days correlate with healthier food choices",
                confidence: confidence,
                dataPoints: Array(refs)
            )
        ]
    }

    // MARK: - Helper Methods

    private func findLateDinnerDays(from snapshots: [DailySmileySnapshot]) -> [DailySmileySnapshot] {
        snapshots.filter { snapshot in
            snapshot.meals.contains { self.isLateDinner($0) }
        }
    }

    private func isLateDinner(_ meal: Meal) -> Bool {
        let hour = Calendar.current.component(.hour, from: meal.timestamp)
        return hour >= self.lateDinnerHour
    }

    private func findPoorSleepDays(from snapshots: [DailySmileySnapshot]) -> [DailySmileySnapshot] {
        snapshots.filter { snapshot in
            snapshot.reflection?.sleepQuality == .poor || snapshot.reflection?.sleepQuality == .terrible
        }
    }

    private func findGoodSleepDays(from snapshots: [DailySmileySnapshot]) -> [DailySmileySnapshot] {
        snapshots.filter { snapshot in
            snapshot.reflection?.sleepQuality == .great || snapshot.reflection?.sleepQuality == .good
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
