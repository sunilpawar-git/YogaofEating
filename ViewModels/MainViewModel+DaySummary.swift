import Foundation

// MARK: - Day Summary (Phase 5)

extension MainViewModel {
    /// Average health score across today's meals, or nil when fewer than 2 meals are logged.
    /// Requires at least 2 meals to match the display threshold used by DayTimelineView's summary line.
    var averageHealthScoreToday: Double? {
        guard self.meals.count >= 2 else { return nil }
        let total = self.meals.reduce(0.0) { $0 + $1.healthScore }
        return total / Double(self.meals.count)
    }
}
