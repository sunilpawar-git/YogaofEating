import Combine
import XCTest

@testable import Yoga_of_Eating

// MARK: - Test-local suspending mock

/// A CloudSyncService mock whose `fetchAllSnapshots` suspends until manually resumed.
/// Used to hold a restore in-flight and verify concurrency guard behaviour.
/// Not placed in Mocks.swift — this mock is specific to concurrency tests here.
@MainActor
private final class SuspendingMockCloudSyncService: CloudSyncServiceProtocol {
    private(set) var fetchCallCount = 0
    private(set) var batchUploadCalled = false
    private var fetchContinuation: CheckedContinuation<SnapshotFetchResult, Error>?

    func fetchAllSnapshots(userId _: String) async throws -> SnapshotFetchResult {
        self.fetchCallCount += 1
        return try await withCheckedThrowingContinuation { cont in
            self.fetchContinuation = cont
        }
    }

    func upload(snapshot _: DailySmileySnapshot, userId _: String) async throws {}

    func uploadBatch(snapshots _: [DailySmileySnapshot], userId _: String) async throws {
        self.batchUploadCalled = true
    }

    func resumeWithResult(_ result: SnapshotFetchResult) {
        self.fetchContinuation?.resume(returning: result)
        self.fetchContinuation = nil
    }

    func resumeWithError(_ error: Error) {
        self.fetchContinuation?.resume(throwing: error)
        self.fetchContinuation = nil
    }
}

// MARK: - ConcurrencyFlagTests

/// Tests for isRestoreInProgress / isSyncInProgress guards on the real HistoricalDataService.
@MainActor
final class ConcurrencyFlagTests: XCTestCase {
    private var mockAuth: MockAuthService!
    private var mockSync: MockCloudSyncService!
    private var mockPersistence: MockPersistenceService!

    override func setUp() {
        super.setUp()
        self.mockAuth = MockAuthService()
        self.mockSync = MockCloudSyncService()
        self.mockPersistence = MockPersistenceService()
        UserDefaults.standard.removeObject(forKey: StorageKeys.lastSignedInUID)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.lastSignedInUID)
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

    // MARK: - Initial state

    func test_isRestoreInProgress_isFalseInitially() {
        let sut = self.makeSut()
        XCTAssertFalse(sut.isRestoreInProgress)
    }

    func test_isSyncInProgress_isFalseInitially() {
        let sut = self.makeSut()
        XCTAssertFalse(sut.isSyncInProgress)
    }

    // MARK: - Flag lifecycle (success path)

    func test_restoreFromFirebase_clearsFlag_onSuccess() async throws {
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        self.mockSync.stubbedFetchedSnapshots = [
            DailySmileySnapshot(
                id: UUID(),
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5
            )
        ]
        let sut = self.makeSut()

        try await sut.restoreFromFirebase()

        XCTAssertFalse(sut.isRestoreInProgress, "Flag must be cleared after successful restore")
    }

    // MARK: - Flag lifecycle (failure path — defer must clear flag)

    func test_restoreFromFirebase_clearsFlag_onFailure() async {
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        self.mockSync.fetchShouldFail = true
        let sut = self.makeSut()

        try? await sut.restoreFromFirebase()

        XCTAssertFalse(sut.isRestoreInProgress, "Flag must be cleared even when restore throws")
    }

    // MARK: - Concurrency: second restore is no-op while first is in progress

    func test_restoreFromFirebase_whenAlreadyInProgress_isNoOp() async throws {
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        let suspending = SuspendingMockCloudSyncService()
        let sut = HistoricalDataService(
            persistenceService: self.mockPersistence,
            authService: self.mockAuth,
            syncService: suspending
        )

        // Start first restore — it suspends at fetchAllSnapshots
        let firstTask = Task { @MainActor in try await sut.restoreFromFirebase() }
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)
        XCTAssertTrue(sut.isRestoreInProgress, "Flag must be set while first restore is suspended")
        XCTAssertEqual(suspending.fetchCallCount, 1, "Precondition: first task reached fetchAllSnapshots")

        // Second call must return immediately without starting a new fetch
        try await sut.restoreFromFirebase()
        XCTAssertEqual(suspending.fetchCallCount, 1, "Fetch must not be called again for concurrent restore")

        suspending.resumeWithResult(SnapshotFetchResult(snapshots: [], skippedCount: 0))
        try await firstTask.value
        XCTAssertFalse(sut.isRestoreInProgress)
    }

    // MARK: - Sync is blocked while a restore is in progress

    func test_syncToFirebase_whenRestoreInProgress_doesNotUpload() async throws {
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: nil, email: nil)
        let suspending = SuspendingMockCloudSyncService()
        let sut = HistoricalDataService(
            persistenceService: self.mockPersistence,
            authService: self.mockAuth,
            syncService: suspending
        )

        // Start restore (suspends at fetchAllSnapshots)
        let restoreTask = Task { @MainActor in try await sut.restoreFromFirebase() }
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        // Attempt sync while restore is in progress — must be a no-op
        try await sut.syncToFirebase()
        XCTAssertFalse(suspending.batchUploadCalled, "Sync must not upload while restore is in progress")

        suspending.resumeWithResult(SnapshotFetchResult(snapshots: [], skippedCount: 0))
        try await restoreTask.value
    }
}

// MARK: - AuthAwareRestoreTests

/// Tests for account-switch detection in MainViewModel.loadData().
@MainActor
final class AuthAwareRestoreTests: XCTestCase {
    private var mockAuth: MockAuthService!
    private var mockHistorical: MockHistoricalDataService!
    private var mockPersistence: MockPersistenceService!

    override func setUp() {
        super.setUp()
        self.mockAuth = MockAuthService()
        self.mockHistorical = MockHistoricalDataService()
        self.mockPersistence = MockPersistenceService()
        UserDefaults.standard.removeObject(forKey: StorageKeys.lastSignedInUID)
        UserDefaults.standard.removeObject(forKey: StorageKeys.hasDeletedAllData)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.lastSignedInUID)
        UserDefaults.standard.removeObject(forKey: StorageKeys.hasDeletedAllData)
        self.mockAuth = nil
        self.mockHistorical = nil
        self.mockPersistence = nil
        super.tearDown()
    }

    private func makeVM() -> MainViewModel {
        MainViewModel(
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            authService: self.mockAuth,
            skipDataLoading: true
        )
    }

    private func stubbedAppData(meals: [Meal] = []) -> PersistenceService.AppData {
        PersistenceService.AppData(
            meals: meals,
            smileyState: .neutral,
            lastResetDate: Date(),
            historicalData: HistoricalData()
        )
    }

    // MARK: - Account switch: different UID

    func test_loadData_whenUIDDiffers_clearsHistoricalDataBeforeRestore() async throws {
        self.mockPersistence.stubbedLoadData = self.stubbedAppData(meals: [MealBuilder().build()])
        UserDefaults.standard.set("oldUID", forKey: StorageKeys.lastSignedInUID)
        self.mockAuth.currentUser = MockAuthUser(uid: "newUID", displayName: nil, email: nil)
        let vm = self.makeVM()

        vm.loadData()
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        XCTAssertTrue(
            self.mockHistorical.clearAllDataCalled,
            "Historical data must be cleared when a different user signs in"
        )
    }

    func test_loadData_whenUIDDiffers_triggersCloudRestoreForNewAccount() async throws {
        self.mockPersistence.stubbedLoadData = self.stubbedAppData(meals: [MealBuilder().build()])
        UserDefaults.standard.set("oldUID", forKey: StorageKeys.lastSignedInUID)
        self.mockAuth.currentUser = MockAuthUser(uid: "newUID", displayName: nil, email: nil)
        let vm = self.makeVM()

        vm.loadData()
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        XCTAssertTrue(
            self.mockHistorical.restoreFromFirebaseCalled,
            "Cloud restore must be triggered for the new account after clearing old data"
        )
    }

    // MARK: - Same user: no clear, no extra restore

    func test_loadData_whenUIDSame_doesNotClearData() {
        self.mockPersistence.stubbedLoadData = self.stubbedAppData(meals: [MealBuilder().build()])
        UserDefaults.standard.set("sameUID", forKey: StorageKeys.lastSignedInUID)
        self.mockAuth.currentUser = MockAuthUser(uid: "sameUID", displayName: nil, email: nil)
        let vm = self.makeVM()

        vm.loadData()

        XCTAssertFalse(
            self.mockHistorical.clearAllDataCalled,
            "Historical data must NOT be cleared when the same user reloads"
        )
    }

    func test_loadData_whenUIDSame_doesNotTriggerCloudRestore() {
        self.mockPersistence.stubbedLoadData = self.stubbedAppData(meals: [MealBuilder().build()])
        UserDefaults.standard.set("sameUID", forKey: StorageKeys.lastSignedInUID)
        self.mockAuth.currentUser = MockAuthUser(uid: "sameUID", displayName: nil, email: nil)
        let vm = self.makeVM()

        vm.loadData()

        XCTAssertFalse(
            self.mockHistorical.restoreFromFirebaseCalled,
            "Cloud restore must NOT be triggered when the same user reloads with a local file"
        )
    }

    // MARK: - UID storage after load

    func test_loadData_updatesLastSignedInUID_afterSuccessfulLoad() {
        self.mockPersistence.stubbedLoadData = self.stubbedAppData()
        self.mockAuth.currentUser = MockAuthUser(uid: "uid123", displayName: nil, email: nil)
        let vm = self.makeVM()

        vm.loadData()

        let storedUID = UserDefaults.standard.string(forKey: StorageKeys.lastSignedInUID)
        XCTAssertEqual(storedUID, "uid123", "Last signed-in UID must be stored after successful load")
    }

    func test_loadData_whenNoPersistenceFile_andSignedIn_triggersCloudRestore() async throws {
        // No local file (stubbedLoadData is nil by default — simulates fresh install)
        self.mockAuth.currentUser = MockAuthUser(uid: "uid456", displayName: nil, email: nil)
        let vm = self.makeVM()

        vm.loadData()
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        XCTAssertTrue(
            self.mockHistorical.restoreFromFirebaseCalled,
            "Cloud restore must be triggered on fresh install when user is signed in"
        )
    }

    func test_triggerCloudRestore_updatesLastSignedInUID_afterSuccessfulRestore() async throws {
        // No local file → goes through triggerCloudRestoreIfNeeded path
        self.mockAuth.currentUser = MockAuthUser(uid: "uid789", displayName: nil, email: nil)
        let vm = self.makeVM()

        vm.loadData()
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        let storedUID = UserDefaults.standard.string(forKey: StorageKeys.lastSignedInUID)
        XCTAssertEqual(
            storedUID,
            "uid789",
            "Last signed-in UID must be stored after successful cloud restore"
        )
    }
}
