import Foundation

// MARK: - Persistence & Query Helpers

extension HistoricalDataService {
    /// Loads historical data from persistent storage.
    /// Called automatically during initialization.
    func loadHistoricalData() -> HistoricalData {
        if let savedData = persistenceService.load() {
            savedData.historicalData
        } else {
            HistoricalData()
        }
    }

    // MARK: - Cloud Sync

    func syncToFirebase() async throws {
        try await self.syncHandler.sync()
        self.saveHistoricalData()
    }

    // MARK: - Cloud Restore

    func restoreFromFirebase() async throws {
        let snapshots = try await self.syncHandler.restore()
        guard !snapshots.isEmpty else { return }
        for snapshot in snapshots {
            self.historicalData.addOrUpdate(snapshot: snapshot)
        }
        self.saveHistoricalData()
    }

    func clearAllData() {
        self.historicalData = HistoricalData()
    }

    // MARK: - Todo Carry-Over

    func incompleteTodosForCarryOver(from date: Date) -> [MindCheckEntry] {
        guard let todos = self.getSnapshot(for: date)?.highlightData?.todos else { return [] }
        return todos
            .filter { $0.category == .todo && $0.isAccomplished != true }
            .map { $0.withCarriedOverCount($0.carriedOverCount + 1) }
    }

    // MARK: - Food Debt Starting State

    func foodDebtStartingState(relativeTo date: Date) -> SmileyState {
        let calendar = Calendar.current
        guard
            let d1 = calendar.date(byAdding: .day, value: -1, to: date),
            let d2 = calendar.date(byAdding: .day, value: -2, to: date),
            let s1 = self.getSnapshot(for: d1),
            s1.mealCount > 0,
            s1.averageHealthScore < ScoringThresholds.foodDebtBadDay,
            let s2 = self.getSnapshot(for: d2),
            s2.mealCount > 0,
            s2.averageHealthScore < ScoringThresholds.foodDebtBadDay
        else { return .neutral }
        return .concerned
    }
}
