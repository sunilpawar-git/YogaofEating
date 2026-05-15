import XCTest
@testable import Yoga_of_Eating

// MARK: - DeleteAllDataFlagTests

/// Tests the `hasDeletedAllData` flag that prevents an accidental cloud restore
/// after a user explicitly deletes all data on this device.
///
/// Edge case addressed: if `saveData()` fails after deleteAllData (e.g., disk full),
/// the app has no local file on next launch → `triggerCloudRestoreIfNeeded()` would
/// normally re-download the just-deleted data. The flag blocks this.
@MainActor
final class DeleteAllDataFlagTests: XCTestCase {
    private var mockHistorical: MockHistoricalDataService!
    private var mockPersistence: MockPersistenceService!
    private var mockAuth: MockAuthService!
    private var testDefaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        self.testDefaults = UserDefaults(suiteName: "DeleteAllDataFlagTests.\(UUID())")!
        self.mockHistorical = MockHistoricalDataService()
        self.mockPersistence = MockPersistenceService()
        self.mockAuth = MockAuthService()
    }

    override func tearDown() async throws {
        self.testDefaults.removePersistentDomain(forName: self.testDefaults.description)
        self.testDefaults = nil
        self.mockHistorical = nil
        self.mockPersistence = nil
        self.mockAuth = nil
        try await super.tearDown()
    }

    private func makeSut() -> MainViewModel {
        MainViewModel(
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            authService: self.mockAuth,
            userDefaults: self.testDefaults,
            skipDataLoading: true
        )
    }

    // MARK: - Flag is set after deleteAllData

    func test_deleteAllData_setsHasDeletedAllDataFlag() {
        let sut = self.makeSut()
        XCTAssertFalse(
            self.testDefaults.bool(forKey: StorageKeys.hasDeletedAllData),
            "Pre-condition: hasDeletedAllData must be false before deletion"
        )
        sut.deleteAllData()
        XCTAssertTrue(
            self.testDefaults.bool(forKey: StorageKeys.hasDeletedAllData),
            "deleteAllData() must set hasDeletedAllData to true in UserDefaults"
        )
    }

    // MARK: - Flag blocks automatic cloud restore

    func test_triggerCloudRestore_whenDeletionFlagIsSet_doesNotRestore() {
        self.testDefaults.set(true, forKey: StorageKeys.hasDeletedAllData)
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        let sut = self.makeSut()
        sut.triggerCloudRestoreIfNeeded()
        // Guard is synchronous — no Task launched, no settle delay needed
        XCTAssertFalse(
            self.mockHistorical.restoreFromFirebaseCalled,
            "Restore must be skipped when hasDeletedAllData flag is set"
        )
    }

    // MARK: - Normal restore proceeds when flag is absent

    func test_triggerCloudRestore_whenDeletionFlagIsNotSet_proceedsWithRestore() async throws {
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        let sut = self.makeSut()
        sut.triggerCloudRestoreIfNeeded()
        try? await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)
        XCTAssertTrue(
            self.mockHistorical.restoreFromFirebaseCalled,
            "Restore must proceed when hasDeletedAllData flag is not set"
        )
    }

    // MARK: - Account switch clears the flag

    func test_loadData_onAccountSwitch_clearsDeletionFlagBeforeRestore() {
        // User 1 deleted their data; User 2 now signs in on the same device
        self.testDefaults.set(true, forKey: StorageKeys.hasDeletedAllData)
        self.testDefaults.set("user1", forKey: StorageKeys.lastSignedInUID)
        self.mockAuth.currentUser = MockAuthUser(uid: "user2", displayName: nil, email: nil)
        self.mockPersistence.stubbedLoadData = PersistenceService.AppData(
            meals: [],
            smileyState: .neutral,
            lastResetDate: Date(),
            historicalData: HistoricalData()
        )
        let sut = self.makeSut()
        sut.loadData()
        XCTAssertFalse(
            self.testDefaults.bool(forKey: StorageKeys.hasDeletedAllData),
            "Account switch must clear hasDeletedAllData so the new user's cloud history can be restored"
        )
    }

    // MARK: - Flag is set before persistence is cleared (atomicity)

    func test_deleteAllData_setsFlagBeforeClearingPersistence() {
        /// Captures the state of `hasDeletedAllData` at the moment `deleteAll()` is called.
        @MainActor class FlagTrackingPersistenceService: MockPersistenceService {
            var flagValueAtDeletion: Bool?
            var userDefaults: UserDefaults = .standard
            override func deleteAll() {
                self.flagValueAtDeletion = self.userDefaults.bool(forKey: StorageKeys.hasDeletedAllData)
                super.deleteAll()
            }
        }
        let tracking = FlagTrackingPersistenceService()
        tracking.userDefaults = self.testDefaults
        let sut = MainViewModel(
            persistenceService: tracking,
            historicalService: mockHistorical,
            authService: mockAuth,
            userDefaults: self.testDefaults,
            skipDataLoading: true
        )
        sut.deleteAllData()
        XCTAssertTrue(
            tracking.flagValueAtDeletion ?? false,
            "hasDeletedAllData must be set BEFORE persistenceService.deleteAll() is called (atomicity guarantee)"
        )
    }
}

// MARK: - PartialRestoreTests

/// Tests that `restoreFromFirebase` gracefully handles partial cloud data
/// (simulates the case where some Firestore documents were corrupt and filtered out).
@MainActor
final class PartialRestoreTests: XCTestCase {
    private var mockSync: MockCloudSyncService!
    private var mockAuth: MockAuthService!
    private var mockPersistence: MockPersistenceService!

    override func setUp() async throws {
        try await super.setUp()
        self.mockSync = MockCloudSyncService()
        self.mockAuth = MockAuthService()
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        self.mockPersistence = MockPersistenceService()
    }

    override func tearDown() async throws {
        self.mockSync = nil
        self.mockAuth = nil
        self.mockPersistence = nil
        try await super.tearDown()
    }

    private func makeSut() -> HistoricalDataService {
        HistoricalDataService(
            persistenceService: self.mockPersistence,
            authService: self.mockAuth,
            syncService: self.mockSync
        )
    }

    // When cloud returns fewer snapshots than stored (some docs were corrupted and silently dropped),
    // all returned valid snapshots must still be merged into historicalData.
    func test_restoreFromFirebase_withPartialCloudData_mergesAllReturnedSnapshots() async throws {
        let snapshot1 = DailySmileySnapshotBuilder().daysAgo(1).build()
        let snapshot2 = DailySmileySnapshotBuilder().daysAgo(2).build()
        // Cloud "had" 3 docs but only 2 decoded successfully (3rd was corrupted)
        self.mockSync.stubbedFetchedSnapshots = [snapshot1, snapshot2]
        let sut = self.makeSut()
        try await sut.restoreFromFirebase()
        XCTAssertEqual(
            sut.historicalData.dailySnapshots.count,
            2,
            "All parseable cloud snapshots must be merged even if some docs were corrupted"
        )
    }
}
