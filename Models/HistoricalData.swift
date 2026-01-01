import Foundation

/// Container for all archived daily snapshots with retrieval and management methods.
/// Maintains snapshots sorted by date (newest first) for efficient access.
struct HistoricalData: Codable {
    // MARK: - Properties

    var dailySnapshots: [DailySmileySnapshot]
    var lastSyncDate: Date?

    // MARK: - Initialization

    init(dailySnapshots: [DailySmileySnapshot] = [], lastSyncDate: Date? = nil) {
        self.dailySnapshots = dailySnapshots.sorted { $0.date > $1.date }
        self.lastSyncDate = lastSyncDate
    }

    // MARK: - Mutating Methods

    /// Adds a new snapshot or updates an existing one for the same day.
    /// Maintains sort order (newest first) after insertion.
    mutating func addOrUpdate(snapshot: DailySmileySnapshot) {
        let calendar = Calendar(identifier: .gregorian)
        let normalizedDate = calendar.startOfDay(for: snapshot.date)

        // Remove existing snapshot for the same day
        self.dailySnapshots.removeAll { existingSnapshot in
            calendar.isDate(existingSnapshot.date, inSameDayAs: normalizedDate)
        }

        // Add new snapshot
        self.dailySnapshots.append(snapshot)

        // Re-sort to maintain newest-first order
        self.dailySnapshots.sort { $0.date > $1.date }
    }

    // MARK: - Retrieval Methods

    /// Returns the snapshot for a specific date, or nil if not found.
    func snapshot(for date: Date) -> DailySmileySnapshot? {
        let calendar = Calendar(identifier: .gregorian)
        let normalizedDate = calendar.startOfDay(for: date)

        return self.dailySnapshots.first { snapshot in
            calendar.isDate(snapshot.date, inSameDayAs: normalizedDate)
        }
    }

    /// Returns all snapshots within a date range (inclusive).
    func snapshots(in range: ClosedRange<Date>) -> [DailySmileySnapshot] {
        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.startOfDay(for: range.lowerBound)
        let endDate = calendar.startOfDay(for: range.upperBound)

        return self.dailySnapshots.filter { snapshot in
            snapshot.date >= startDate && snapshot.date <= endDate
        }
    }
}
