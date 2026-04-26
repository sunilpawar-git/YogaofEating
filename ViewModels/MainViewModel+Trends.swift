import Foundation

// MARK: - Trends & Archetype Extension

extension MainViewModel {
    /// Current energy archetype, classified from the past 14 days of data.
    /// Computed lazily on the fly; not expensive enough to cache.
    var currentArchetype: EnergyArchetype {
        ArchetypeClassifier.classify(
            snapshots: self.historicalService.historicalData.dailySnapshots
        )
    }

    /// Trend data points for the given number of days.
    func trendPoints(days: Int) -> [TrendPoint] {
        TrendDataService.buildTrendPoints(
            snapshots: self.historicalService.historicalData.dailySnapshots,
            days: days
        )
    }
}
