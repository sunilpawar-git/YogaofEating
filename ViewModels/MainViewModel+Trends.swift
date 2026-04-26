import Foundation

// MARK: - Trends, Archetype & Streak Extension

extension MainViewModel {
    var currentArchetype: EnergyArchetype {
        ArchetypeClassifier.classify(
            snapshots: self.historicalService.historicalData.dailySnapshots
        )
    }

    func trendPoints(days: Int) -> [TrendPoint] {
        TrendDataService.buildTrendPoints(
            snapshots: self.historicalService.historicalData.dailySnapshots,
            days: days
        )
    }

    var currentStreak: ConsistencyStreak {
        ConsistencyStreakService.compute(
            from: self.historicalService.historicalData.dailySnapshots,
            todayLoggedOverride: self.meals.isEmpty ? nil : true
        )
    }
}
