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

    /// Delay between consecutive retry attempts. Defaults to `TimingConstants.syncRetryDelayNanoseconds`.
    /// Override in tests with `0` for instant retries.
    private let retryDelayNanoseconds: UInt64

    // MARK: - Init

    init(
        authService: any AuthServiceProtocol,
        syncService: any CloudSyncServiceProtocol,
        snapshotsProvider: @escaping @MainActor () -> [DailySmileySnapshot],
        lastSyncDateProvider: @escaping @MainActor () -> Date?,
        onSyncCompleted: @escaping @MainActor (Date) -> Void,
        retryDelayNanoseconds: UInt64? = nil
    ) {
        self.authService = authService
        self.syncService = syncService
        self.snapshotsProvider = snapshotsProvider
        self.lastSyncDateProvider = lastSyncDateProvider
        self.onSyncCompleted = onSyncCompleted
        self.retryDelayNanoseconds = retryDelayNanoseconds ?? TimingConstants.syncRetryDelayNanoseconds
    }

    // MARK: - Restore

    /// Downloads all snapshots from Firebase for the authenticated user.
    /// Retries up to `TimingConstants.syncMaxRetryAttempts` times on transient failures.
    /// - Throws: `AppError.syncAuthRequired` when no authenticated user exists (not retried).
    /// - Returns: All stored snapshots, or an empty array when the cloud has no data.
    ///
    /// After a successful call, `lastRestoreSkippedCount` reflects how many cloud documents
    /// could not be decoded. Callers can inspect this value to surface partial-restore warnings.
    private(set) var lastRestoreSkippedCount: Int = 0

    func restore() async throws -> [DailySmileySnapshot] {
        guard let userId = self.authService.currentUser?.uid else {
            syncLogger.warning("Restore attempted without authenticated user")
            throw AppError.syncAuthRequired
        }

        let result = try await withRetry {
            try await self.syncService.fetchAllSnapshots(userId: userId)
        }
        self.lastRestoreSkippedCount = result.skippedCount
        syncLogger.info("Restore: fetched \(result.snapshots.count) snapshots for user")
        return result.snapshots
    }

    // MARK: - Sync

    /// Uploads snapshots to Firebase.
    /// - Performs a delta sync when `lastSyncDate` is set and in the past (only uploads since cutoff).
    /// - Performs a full sync on first call (`lastSyncDate` is nil) or when the stored date is
    ///   in the future (clock skew guard — avoids silently skipping a full sync).
    /// - Retries up to `TimingConstants.syncMaxRetryAttempts` times on transient upload failures.
    /// - Calls `onSyncCompleted` with the current timestamp on success.
    /// - Throws `AppError.syncAuthRequired` when no authenticated user exists (not retried).
    func sync() async throws {
        guard let userId = self.authService.currentUser?.uid else {
            syncLogger.warning("Sync attempted without authenticated user")
            throw AppError.syncAuthRequired
        }

        let allSnapshots = self.snapshotsProvider()
        let snapshotsToSync: [DailySmileySnapshot]

        // Guard against clock skew: if lastSyncDate is in the future (device clock was wrong),
        // treat it as nil to force a full sync rather than a missed delta sync.
        let rawSyncDate = self.lastSyncDateProvider()
        let safeSyncDate = rawSyncDate.flatMap { $0 > Date() ? nil : $0 }

        if let safeSyncDate {
            let cutoff = Calendar.current.startOfDay(for: safeSyncDate)
            snapshotsToSync = allSnapshots.filter { $0.date >= cutoff }
            syncLogger.info("Delta sync: \(snapshotsToSync.count) snapshots since \(safeSyncDate, privacy: .public)")
        } else {
            snapshotsToSync = allSnapshots
            syncLogger.info("Full sync: \(snapshotsToSync.count) snapshots")
        }

        try await self.withRetry {
            try await self.syncService.uploadBatch(snapshots: snapshotsToSync, userId: userId)
        }

        let completedAt = Date()
        self.onSyncCompleted(completedAt)
        syncLogger.info("Sync completed at \(completedAt, privacy: .public)")
    }

    // MARK: - Retry

    /// Retries `operation` up to `TimingConstants.syncMaxRetryAttempts` times.
    /// Waits `retryDelayNanoseconds` between consecutive attempts.
    /// Rethrows `AppError.syncAuthRequired` immediately — auth failures are never retried.
    private func withRetry<T>(_ operation: () async throws -> T) async throws -> T {
        var attempt = 0
        var lastError: Error?
        while attempt < TimingConstants.syncMaxRetryAttempts {
            attempt += 1
            do {
                return try await operation()
            } catch AppError.syncAuthRequired {
                throw AppError.syncAuthRequired
            } catch {
                lastError = error
                if attempt < TimingConstants.syncMaxRetryAttempts {
                    syncLogger.warning(
                        "Attempt \(attempt)/\(TimingConstants.syncMaxRetryAttempts) failed: \(error.localizedDescription, privacy: .private). Retrying."
                    )
                    try? await Task.sleep(nanoseconds: self.retryDelayNanoseconds)
                }
            }
        }
        syncLogger.error("Operation failed after \(TimingConstants.syncMaxRetryAttempts) attempts")
        throw lastError ?? AppError.syncUploadFailed(
            underlying: NSError(domain: "HistoricalSync", code: -1, userInfo: nil)
        )
    }
}
