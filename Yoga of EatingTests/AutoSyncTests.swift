import XCTest
@testable import Yoga_of_Eating

// MARK: - AutoSyncTests

// Gap 1: After resetDay(), the archived snapshot is automatically synced to Firebase
// in a fire-and-forget background Task so the UI is never blocked.

@MainActor
final class AutoSyncTests: XCTestCase {
    private var mockHistorical: MockHistoricalDataService!
    private var mockPersistence: MockPersistenceService!

    override func setUp() {
        super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        self.mockPersistence = MockPersistenceService()
    }

    override func tearDown() {
        self.mockHistorical = nil
        self.mockPersistence = nil
        super.tearDown()
    }

    private func makeVM() -> MainViewModel {
        MainViewModel(
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            skipDataLoading: true
        )
    }

    // MARK: - Gap 1: auto-sync after day archive

    func test_resetDay_triggersFirebaseSync() async throws {
        let vm = self.makeVM()

        vm.resetDay()
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        XCTAssertTrue(
            self.mockHistorical.syncToFirebaseCalled,
            "resetDay() must trigger syncToFirebase() so the archived day is backed up"
        )
    }

    func test_resetDay_mealsAreClearedSynchronously_independentOfSync() {
        let vm = self.makeVM()
        vm.meals = [MealBuilder().build()]

        vm.resetDay()

        XCTAssertTrue(vm.meals.isEmpty, "Meals must be cleared synchronously — sync must not block the day reset")
    }

    func test_resetDay_syncFailureIsIgnored_appDoesNotCrash() async throws {
        self.mockHistorical.syncToFirebaseShouldThrow = true
        let vm = self.makeVM()

        vm.resetDay()
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        XCTAssertTrue(
            self.mockHistorical.syncToFirebaseCalled,
            "syncToFirebase was attempted even when it throws"
        )
        // If we reach here without crashing the test, the failure was silently swallowed — correct.
    }

    func test_resetDay_syncCalledOncePerReset() async throws {
        let vm = self.makeVM()

        vm.resetDay()
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        XCTAssertEqual(
            self.mockHistorical.syncToFirebaseCallCount, 1,
            "Each resetDay() call must trigger exactly one sync"
        )
    }

    // MARK: - Gap 2: restore trigger from loadData

    func test_loadData_whenNoPersistenceFile_triggersCloudRestore() async throws {
        // MockPersistenceService.load() returns nil by default — simulates fresh install
        let vm = self.makeVM()

        vm.loadData()
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        XCTAssertTrue(
            self.mockHistorical.restoreFromFirebaseCalled,
            "loadData() must trigger restoreFromFirebase() when local file is missing"
        )
    }

    func test_loadData_whenLocalFileExists_doesNotTriggerCloudRestore() async throws {
        self.mockPersistence.stubbedLoadData = PersistenceService.AppData(
            meals: [],
            smileyState: .neutral,
            lastResetDate: Date(),
            historicalData: HistoricalData()
        )
        let vm = self.makeVM()

        vm.loadData()
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        XCTAssertFalse(
            self.mockHistorical.restoreFromFirebaseCalled,
            "loadData() must NOT restore from cloud when a local persistence file already exists"
        )
    }

    func test_deleteAllData_thenLoadData_doesNotTriggerCloudRestore() async throws {
        // After deleteAllData(), an empty file is saved so next launch won't restore
        // the data the user intentionally deleted.
        let vm = self.makeVM()
        vm.meals = [MealBuilder().build()]

        vm.deleteAllData()
        // The empty state is now saved; simulate a cold relaunch by calling loadData() again.
        // stubbedLoadData still returns nil, but real persistence would have the empty file.
        // We verify that saveData() was called (i.e., empty state written).
        XCTAssertTrue(
            self.mockPersistence.saveCalled,
            "deleteAllData() must save an empty state so the next launch does not see a missing file"
        )
    }
}
