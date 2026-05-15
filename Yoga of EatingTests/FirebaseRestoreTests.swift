import XCTest
@testable import Yoga_of_Eating

// MARK: - HistoricalSyncRestoreTests

// Unit tests for HistoricalSyncService.restore() — the new download path.

@MainActor
final class HistoricalSyncRestoreTests: XCTestCase {
    private var mockAuth: MockAuthService!
    private var mockSync: MockCloudSyncService!

    override func setUp() {
        super.setUp()
        self.mockAuth = MockAuthService()
        self.mockSync = MockCloudSyncService()
    }

    override func tearDown() {
        self.mockAuth = nil
        self.mockSync = nil
        super.tearDown()
    }

    private func makeSut(snapshots: [DailySmileySnapshot] = []) -> HistoricalSyncService {
        HistoricalSyncService(
            authService: self.mockAuth,
            syncService: self.mockSync,
            snapshotsProvider: { snapshots },
            lastSyncDateProvider: { nil },
            onSyncCompleted: { _ in }
        )
    }

    func test_restore_throwsSyncAuthRequired_whenNoUser() async {
        self.mockAuth.currentUser = nil
        let sut = self.makeSut()

        do {
            _ = try await sut.restore()
            XCTFail("Expected syncAuthRequired")
        } catch AppError.syncAuthRequired {
            // correct
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_restore_returnsSnapshots_whenAuthenticated() async throws {
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        let snap = DailySmileySnapshotBuilder().daysAgo(1).build()
        self.mockSync.stubbedFetchedSnapshots = [snap]
        let sut = self.makeSut()

        let result = try await sut.restore()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, snap.id)
    }

    func test_restore_returnsEmptyArray_whenCloudHasNoData() async throws {
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        self.mockSync.stubbedFetchedSnapshots = []
        let sut = self.makeSut()

        let result = try await sut.restore()

        XCTAssertTrue(result.isEmpty)
    }

    func test_restore_passesThroughUploadError() async {
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        self.mockSync.fetchShouldFail = true
        let sut = self.makeSut()

        do {
            _ = try await sut.restore()
            XCTFail("Expected error from failing fetch")
        } catch {
            // correct — fetch error propagates
        }
    }
}

// MARK: - FirebaseRestoreIntegrationTests

// Tests for HistoricalDataService.restoreFromFirebase() — the full restore flow.

@MainActor
final class FirebaseRestoreIntegrationTests: XCTestCase {
    private var mockAuth: MockAuthService!
    private var mockSync: MockCloudSyncService!
    private var mockPersistence: MockPersistenceService!

    override func setUp() {
        super.setUp()
        self.mockAuth = MockAuthService()
        self.mockSync = MockCloudSyncService()
        self.mockPersistence = MockPersistenceService()
    }

    override func tearDown() {
        self.mockAuth = nil
        self.mockSync = nil
        self.mockPersistence = nil
        super.tearDown()
    }

    private func makeSut() -> HistoricalDataService {
        HistoricalDataService(
            persistenceService: self.mockPersistence,
            authService: self.mockAuth,
            syncService: self.mockSync
        )
    }

    func test_restoreFromFirebase_populatesHistoricalDataFromCloud() async throws {
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        let snap1 = DailySmileySnapshotBuilder().daysAgo(1).build()
        let snap2 = DailySmileySnapshotBuilder().daysAgo(2).build()
        self.mockSync.stubbedFetchedSnapshots = [snap1, snap2]
        let sut = self.makeSut()

        try await sut.restoreFromFirebase()

        XCTAssertEqual(sut.historicalData.dailySnapshots.count, 2)
        XCTAssertTrue(sut.historicalData.dailySnapshots.contains { $0.id == snap1.id })
        XCTAssertTrue(sut.historicalData.dailySnapshots.contains { $0.id == snap2.id })
    }

    func test_restoreFromFirebase_savesToDisk_afterSuccessfulRestore() async throws {
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        self.mockSync.stubbedFetchedSnapshots = [DailySmileySnapshotBuilder().daysAgo(1).build()]
        let sut = self.makeSut()

        try await sut.restoreFromFirebase()

        XCTAssertTrue(
            self.mockPersistence.saveCalled,
            "Restored data must be persisted to disk immediately"
        )
    }

    func test_restoreFromFirebase_whenNotAuthenticated_throwsSyncAuthRequired() async {
        self.mockAuth.currentUser = nil
        let sut = self.makeSut()

        do {
            try await sut.restoreFromFirebase()
            XCTFail("Expected syncAuthRequired")
        } catch AppError.syncAuthRequired {
            // correct
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_restoreFromFirebase_whenCloudIsEmpty_historicalDataRemainsEmpty() async throws {
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        self.mockSync.stubbedFetchedSnapshots = []
        let sut = self.makeSut()

        try await sut.restoreFromFirebase()

        XCTAssertTrue(sut.historicalData.dailySnapshots.isEmpty)
    }

    func test_restoreFromFirebase_whenCloudIsEmpty_doesNotSaveToDisk() async throws {
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        self.mockSync.stubbedFetchedSnapshots = []
        let sut = self.makeSut()

        try await sut.restoreFromFirebase()

        XCTAssertFalse(
            self.mockPersistence.saveCalled,
            "No disk write needed when cloud has no data to restore"
        )
    }

    func test_restoreFromFirebase_preservesExistingLocalSnapshots() async throws {
        // If local data exists alongside cloud data, merge — don't overwrite.
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        let localSnap = DailySmileySnapshotBuilder().daysAgo(3).build()
        let cloudSnap = DailySmileySnapshotBuilder().daysAgo(1).build()
        self.mockSync.stubbedFetchedSnapshots = [cloudSnap]
        let sut = self.makeSut()
        sut.historicalData.addOrUpdate(snapshot: localSnap)

        try await sut.restoreFromFirebase()

        XCTAssertEqual(sut.historicalData.dailySnapshots.count, 2)
        XCTAssertTrue(sut.historicalData.dailySnapshots.contains { $0.id == localSnap.id })
        XCTAssertTrue(sut.historicalData.dailySnapshots.contains { $0.id == cloudSnap.id })
    }

    // MARK: - Partial restore (A3 / G1)

    func test_restoreFromFirebase_whenSomeDocumentsCorrupted_throwsRestorePartialData() async {
        // Stub: 2 valid snapshots fetched but 1 cloud document was corrupted (skippedCount = 1).
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        let snap1 = DailySmileySnapshotBuilder().daysAgo(1).build()
        let snap2 = DailySmileySnapshotBuilder().daysAgo(2).build()
        self.mockSync.stubbedFetchedSnapshots = [snap1, snap2]
        self.mockSync.stubbedSkippedCount = 1
        let sut = self.makeSut()

        do {
            try await sut.restoreFromFirebase()
            XCTFail("Expected AppError.restorePartialData to be thrown")
        } catch let AppError.restorePartialData(count) {
            XCTAssertEqual(count, 1, "Skipped count must match the stubbed value")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_restoreFromFirebase_whenSomeDocumentsCorrupted_stillMergesValidSnapshots() async {
        // Even though a partial-data error is thrown, the valid snapshots must be committed.
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        let snap1 = DailySmileySnapshotBuilder().daysAgo(1).build()
        let snap2 = DailySmileySnapshotBuilder().daysAgo(2).build()
        self.mockSync.stubbedFetchedSnapshots = [snap1, snap2]
        self.mockSync.stubbedSkippedCount = 1
        let sut = self.makeSut()

        try? await sut.restoreFromFirebase() // partial error expected — swallow it here

        XCTAssertEqual(sut.historicalData.dailySnapshots.count, 2, "Valid snapshots must be merged despite corruption")
        XCTAssertTrue(self.mockPersistence.saveCalled, "Valid snapshots must be persisted even on partial restore")
    }
}
