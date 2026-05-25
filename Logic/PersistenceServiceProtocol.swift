import Foundation

/// Protocol for persistence operations to enable testing.
@MainActor
protocol PersistenceServiceProtocol {
    func load() -> PersistenceService.AppData?
    func save(
        meals: [Meal],
        smileyState: SmileyState,
        lastResetDate: Date,
        historicalData: HistoricalData,
        nudgeHistory: [NudgeHistoryEntry]
    )
    func deleteAll()
}
