import XCTest
@testable import Yoga_of_Eating

// MARK: - RetryTests

/// Tests retry policy for `HistoricalSyncService.restore()` and `sync()`.
/// `HistoricalSyncService` is created directly (not via `HistoricalDataService`)
/// so we can inject `retryDelayNanoseconds: 0` for instant retries.
@MainActor
final class RetryTests: XCTestCase {
    private var mockAuth: MockAuthService!
    private var mockSync: MockCloudSyncService!

    override func setUp() async throws {
        try await super.setUp()
        self.mockAuth = MockAuthService()
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        self.mockSync = MockCloudSyncService()
    }

    override func tearDown() async throws {
        self.mockAuth = nil
        self.mockSync = nil
        try await super.tearDown()
    }

    private func makeSut(
        snapshotsProvider: @escaping @MainActor () -> [DailySmileySnapshot] = { [] },
        lastSyncDateProvider: @escaping @MainActor () -> Date? = { nil }
    ) -> HistoricalSyncService {
        HistoricalSyncService(
            authService: self.mockAuth,
            syncService: self.mockSync,
            snapshotsProvider: snapshotsProvider,
            lastSyncDateProvider: lastSyncDateProvider,
            onSyncCompleted: { _ in },
            retryDelayNanoseconds: 0
        )
    }

    // MARK: - Restore: success path

    func test_restore_onFirstAttemptSuccess_callsFetchExactlyOnce() async throws {
        let sut = self.makeSut()
        _ = try await sut.restore()
        XCTAssertEqual(self.mockSync.fetchCallCount, 1, "Successful restore must not trigger extra fetch calls")
    }

    // MARK: - Restore: retry on transient failure

    func test_restore_retriesOnTransientFailure_andSucceedsOnSecondAttempt() async throws {
        self.mockSync.fetchFailFirstNTimes = 1 // fail once, then succeed
        let sut = self.makeSut()
        _ = try await sut.restore()
        XCTAssertEqual(self.mockSync.fetchCallCount, 2, "Restore must retry once after a transient failure")
    }

    // MARK: - Restore: exhausted retries

    func test_restore_failsAfterMaxRetryAttempts() async throws {
        self.mockSync.fetchFailFirstNTimes = TimingConstants.syncMaxRetryAttempts // fail all attempts
        let sut = self.makeSut()
        do {
            _ = try await sut.restore()
            XCTFail("Expected error after exhausting all retry attempts")
        } catch {
            XCTAssertEqual(
                self.mockSync.fetchCallCount,
                TimingConstants.syncMaxRetryAttempts,
                "Fetch must be called exactly syncMaxRetryAttempts (\(TimingConstants.syncMaxRetryAttempts)) times before giving up"
            )
        }
    }

    // MARK: - Restore: auth failure is not retried

    func test_restore_authFailure_doesNotRetry() async throws {
        self.mockAuth.currentUser = nil
        let sut = self.makeSut()
        do {
            _ = try await sut.restore()
            XCTFail("Expected AppError.syncAuthRequired")
        } catch AppError.syncAuthRequired {
            XCTAssertEqual(self.mockSync.fetchCallCount, 0, "Auth failure must not reach the network layer")
        }
    }

    // MARK: - Sync: retry on transient failure

    func test_sync_retriesOnTransientFailure_andSucceedsOnSecondAttempt() async throws {
        let snapshot = DailySmileySnapshotBuilder().daysAgo(1).build()
        self.mockSync.uploadFailFirstNTimes = 1 // fail once, then succeed
        let sut = self.makeSut(snapshotsProvider: { [snapshot] })
        try await sut.sync()
        XCTAssertEqual(self.mockSync.uploadCallCount, 2, "Sync upload must be retried once after a transient failure")
    }

    // MARK: - Sync: exhausted retries

    func test_sync_failsAfterMaxRetryAttempts() async throws {
        let snapshot = DailySmileySnapshotBuilder().daysAgo(1).build()
        self.mockSync.uploadFailFirstNTimes = TimingConstants.syncMaxRetryAttempts
        let sut = self.makeSut(snapshotsProvider: { [snapshot] })
        do {
            try await sut.sync()
            XCTFail("Expected error after exhausting all retry attempts")
        } catch {
            XCTAssertEqual(
                self.mockSync.uploadCallCount,
                TimingConstants.syncMaxRetryAttempts,
                "Upload must be called exactly syncMaxRetryAttempts (\(TimingConstants.syncMaxRetryAttempts)) times before giving up"
            )
        }
    }
}

// MARK: - ClockSkewTests

/// Tests the clock-skew guard in `HistoricalSyncService.sync()`.
/// If `lastSyncDate` is in the future (device clock was wrong), treat it as nil
/// and force a full sync rather than an empty delta sync.
@MainActor
final class ClockSkewTests: XCTestCase {
    private var mockAuth: MockAuthService!
    private var mockSync: MockCloudSyncService!

    override func setUp() async throws {
        try await super.setUp()
        self.mockAuth = MockAuthService()
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        self.mockSync = MockCloudSyncService()
    }

    override func tearDown() async throws {
        self.mockAuth = nil
        self.mockSync = nil
        try await super.tearDown()
    }

    private func makeSut(
        snapshotsProvider: @escaping @MainActor () -> [DailySmileySnapshot],
        lastSyncDateProvider: @escaping @MainActor () -> Date?
    ) -> HistoricalSyncService {
        HistoricalSyncService(
            authService: self.mockAuth,
            syncService: self.mockSync,
            snapshotsProvider: snapshotsProvider,
            lastSyncDateProvider: lastSyncDateProvider,
            onSyncCompleted: { _ in },
            retryDelayNanoseconds: 0
        )
    }

    // MARK: - Clock skew: future lastSyncDate → full sync

    func test_sync_whenLastSyncDateIsInFuture_performsFullSync() async throws {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour ahead
        let snapshots = (1...3).map { DailySmileySnapshotBuilder().daysAgo($0).build() }
        let sut = self.makeSut(
            snapshotsProvider: { snapshots },
            lastSyncDateProvider: { futureDate }
        )
        try await sut.sync()
        XCTAssertEqual(
            self.mockSync.batchUploadedSnapshotCount,
            3,
            "A future lastSyncDate (clock skew) must force a full sync of all snapshots"
        )
    }

    // MARK: - Normal delta sync is preserved as regression guard

    func test_sync_whenLastSyncDateIsInPast_performsDeltaSync() async throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let oldSnapshot = DailySmileySnapshotBuilder().daysAgo(5).build()
        let recentSnapshot = DailySmileySnapshotBuilder().daysAgo(1).build()
        let sut = self.makeSut(
            snapshotsProvider: { [oldSnapshot, recentSnapshot] },
            lastSyncDateProvider: { yesterday }
        )
        try await sut.sync()
        XCTAssertEqual(
            self.mockSync.batchUploadedSnapshotCount,
            1,
            "A past lastSyncDate must trigger a delta sync (only recent snapshots)"
        )
    }
}
