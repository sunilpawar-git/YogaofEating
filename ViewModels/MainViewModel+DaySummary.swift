import Foundation

// MARK: - Day Summary (Phase 5)

extension MainViewModel {
    /// Average health score across all of today's meals, or nil when no meals are logged.
    /// Used to render the ambient day summary line above the smiley.
    var averageHealthScoreToday: Double? {
        guard !self.meals.isEmpty else { return nil }
        let total = self.meals.reduce(0.0) { $0 + $1.healthScore }
        return total / Double(self.meals.count)
    }
}
