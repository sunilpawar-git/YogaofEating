import Foundation

// MARK: - Persistence & Query Helpers

extension HistoricalDataService {
    // MARK: - Cloud Sync

    func syncToFirebase() async throws {
        // Block uploads while a restore is in progress to avoid overwriting incoming cloud data.
        guard !self.isRestoreInProgress else { return }
        self.isSyncInProgress = true
        defer { self.isSyncInProgress = false }
        try await self.syncHandler.sync()
        // No saveHistoricalData() here — sync is a read-only upload; local state is unchanged.
    }

    // MARK: - Cloud Restore

    func restoreFromFirebase() async throws {
        // Guard against concurrent restore calls — second call returns immediately.
        guard !self.isRestoreInProgress else { return }
        self.isRestoreInProgress = true
        defer { self.isRestoreInProgress = false }
        let snapshots = try await self.syncHandler.restore()
        // Merge valid snapshots regardless of whether some documents were corrupted —
        // partial data is more valuable to the user than no data.
        for snapshot in snapshots {
            self.historicalData.addOrUpdate(snapshot: snapshot)
        }
        if !snapshots.isEmpty {
            self.saveHistoricalData()
        }
        // Surface the partial-restore warning AFTER committing what was recovered.
        let skipped = self.syncHandler.lastRestoreSkippedCount
        if skipped > 0 {
            throw AppError.restorePartialData(skippedCount: skipped)
        }
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
