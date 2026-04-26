import Foundation

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
        patterns.append(contentsOf: self.analyzeTodoCompletionTrend(from: snapshots))

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
