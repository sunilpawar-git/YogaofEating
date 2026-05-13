import Foundation
import OSLog

private let syncLogger = Logger(subsystem: "com.yogaofeating", category: "HistoricalSync")

/// Handles all cloud synchronization for historical snapshot data.
/// Extracted from `HistoricalDataService` so storage/archival and cloud sync
/// each have a single reason to change (SRP).
///
/// `HistoricalSyncService` is deliberately free of `@Published` state and
/// `ObservableObject` conformance — it is a pure async operation handler.
/// All state mutations are returned to the caller via the `onSyncCompleted` closure.
@MainActor
final class HistoricalSyncService {
    // MARK: - Dependencies

    private let authService: any AuthServiceProtocol
    private let syncService: any CloudSyncServiceProtocol

    /// Returns the current full snapshot array (read from the owning service at call time).
    private let snapshotsProvider: @MainActor () -> [DailySmileySnapshot]

    /// Returns the last sync date recorded by the owning service (nil = never synced).
    private let lastSyncDateProvider: @MainActor () -> Date?

    /// Called on successful upload with the new `lastSyncDate` value to write back.
    private let onSyncCompleted: @MainActor (Date) -> Void

    // MARK: - Init

    init(
        authService: any AuthServiceProtocol,
        syncService: any CloudSyncServiceProtocol,
        snapshotsProvider: @escaping @MainActor () -> [DailySmileySnapshot],
        lastSyncDateProvider: @escaping @MainActor () -> Date?,
        onSyncCompleted: @escaping @MainActor (Date) -> Void
    ) {
        self.authService = authService
        self.syncService = syncService
        self.snapshotsProvider = snapshotsProvider
        self.lastSyncDateProvider = lastSyncDateProvider
        self.onSyncCompleted = onSyncCompleted
    }

    // MARK: - Restore

    /// Downloads all snapshots from Firebase for the authenticated user.
    /// - Throws: `AppError.syncAuthRequired` when no authenticated user exists.
    /// - Returns: All stored snapshots, or an empty array when the cloud has no data.
    func restore() async throws -> [DailySmileySnapshot] {
        guard let userId = self.authService.currentUser?.uid else {
            syncLogger.warning("Restore attempted without authenticated user")
            throw AppError.syncAuthRequired
        }

        let snapshots = try await self.syncService.fetchAllSnapshots(userId: userId)
        syncLogger.info("Restore: fetched \(snapshots.count) snapshots for user")
        return snapshots
    }

    // MARK: - Sync

    /// Uploads snapshots to Firebase.
    /// - Performs a delta sync when `lastSyncDate` is set (only uploads since cutoff).
    /// - Performs a full sync on first call (`lastSyncDate` is nil).
    /// - Calls `onSyncCompleted` with the current timestamp on success.
    /// - Throws `AppError.syncAuthRequired` when no authenticated user exists.
    func sync() async throws {
        guard let userId = self.authService.currentUser?.uid else {
            syncLogger.warning("Sync attempted without authenticated user")
            throw AppError.syncAuthRequired
        }

        let allSnapshots = self.snapshotsProvider()
        let snapshotsToSync: [DailySmileySnapshot]

        if let lastSyncDate = self.lastSyncDateProvider() {
            let cutoff = Calendar.current.startOfDay(for: lastSyncDate)
            snapshotsToSync = allSnapshots.filter { $0.date >= cutoff }
            syncLogger.info("Delta sync: \(snapshotsToSync.count) snapshots since \(lastSyncDate, privacy: .public)")
        } else {
            snapshotsToSync = allSnapshots
            syncLogger.info("Full sync: \(snapshotsToSync.count) snapshots")
        }

        try await self.syncService.uploadBatch(snapshots: snapshotsToSync, userId: userId)

        let completedAt = Date()
        self.onSyncCompleted(completedAt)
        syncLogger.info("Sync completed at \(completedAt, privacy: .public)")
    }
}
