import Foundation

/// Aggregated analytics for todo/task completion across multiple days.
struct TodoAnalytics: Equatable {
    /// Fraction of todos completed (0.0-1.0)
    let completionRate: Double

    /// Consecutive days (ending today) with >50% completion
    let currentStreak: Int

    /// Longest streak of consecutive days with >50% completion
    let bestStreak: Int

    /// Total todos marked as completed across all days
    let totalCompleted: Int

    /// Total todos created across all days
    let totalCreated: Int

    /// Average number of todos completed per day (across days with todos)
    let averagePerDay: Double

    static let empty = TodoAnalytics(
        completionRate: 0,
        currentStreak: 0,
        bestStreak: 0,
        totalCompleted: 0,
        totalCreated: 0,
        averagePerDay: 0
    )
}

/// Pure-function service computing todo completion analytics from snapshots.
enum TodoAnalyticsService {
    /// Computes aggregated todo analytics from historical snapshots.
    /// Only counts `MindCheckEntry` items with `.todo` category.
    static func compute(from snapshots: [DailySmileySnapshot]) -> TodoAnalytics {
        let dailyStats = Self.extractDailyTodoStats(from: snapshots)

        guard !dailyStats.isEmpty else {
            return .empty
        }

        let totalCreated = dailyStats.map(\.created).reduce(0, +)
        let totalCompleted = dailyStats.map(\.completed).reduce(0, +)

        let completionRate: Double = totalCreated > 0
            ? Double(totalCompleted) / Double(totalCreated)
            : 0.0

        let daysWithTodos = dailyStats.count(where: { $0.created > 0 })
        let averagePerDay: Double = daysWithTodos > 0
            ? Double(totalCompleted) / Double(daysWithTodos)
            : 0.0

        let (currentStreak, bestStreak) = Self.computeStreaks(from: dailyStats)

        return TodoAnalytics(
            completionRate: completionRate,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            totalCompleted: totalCompleted,
            totalCreated: totalCreated,
            averagePerDay: averagePerDay
        )
    }
}

// MARK: - Private Helpers

extension TodoAnalyticsService {
    private struct DailyTodoStats {
        let date: Date
        let created: Int
        let completed: Int

        var completionRate: Double {
            self.created > 0
                ? Double(self.completed) / Double(self.created)
                : 0.0
        }
    }

    private static func extractDailyTodoStats(
        from snapshots: [DailySmileySnapshot]
    ) -> [DailyTodoStats] {
        snapshots.compactMap { snapshot -> DailyTodoStats? in
            guard let entries = snapshot.morningMindCheck else { return nil }
            let todos = entries.filter { $0.category == .todo }
            guard !todos.isEmpty else { return nil }

            let completed = todos.count(where: { $0.isAccomplished == true })
            return DailyTodoStats(
                date: snapshot.date,
                created: todos.count,
                completed: completed
            )
        }
    }

    private static func computeStreaks(
        from stats: [DailyTodoStats]
    ) -> (current: Int, best: Int) {
        let sorted = stats
            .filter { $0.created > 0 }
            .sorted { $0.date > $1.date }
        let goodDays = sorted.map { $0.completionRate > 0.5 }

        let currentStreak = Self.leadingTrueCount(goodDays)
        let bestStreak = Self.longestTrueRun(goodDays)
        return (currentStreak, bestStreak)
    }

    private static func leadingTrueCount(_ values: [Bool]) -> Int {
        var count = 0
        for val in values {
            guard val else { break }
            count += 1
        }
        return count
    }

    private static func longestTrueRun(_ values: [Bool]) -> Int {
        var best = 0
        var current = 0
        for val in values {
            if val {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }
}
