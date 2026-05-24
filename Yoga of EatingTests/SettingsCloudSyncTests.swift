import XCTest
@testable import Yoga_of_Eating

/// Unit tests for SettingsViewModel cloud sync state machine.
///
/// Mirrors ManualRestoreTests for the *sync* direction.
/// RED phase: tests for `Strings.Settings.syncButton*` constants and syncStatusText SSOT
/// will fail until those strings are added to Strings.swift and syncStatusText is updated.
@MainActor
final class SettingsCloudSyncTests: XCTestCase {
    private var mockHistorical: MockHistoricalDataService!
    private var mockAuth: MockAuthService!
    private var testDefaults: UserDefaults!
    private var sut: SettingsViewModel!

    override func setUp() async throws {
        try await super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        self.mockAuth = MockAuthService()
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: "Test", email: "test@test.com")
        self.testDefaults = UserDefaults(suiteName: "SettingsCloudSyncTests.\(UUID().uuidString)")
        self.sut = SettingsViewModel(
            historicalService: self.mockHistorical,
            authService: self.mockAuth,
            userDefaults: self.testDefaults
        )
    }

    override func tearDown() async throws {
        self.sut.cancelCloudSync()
        self.sut = nil
        self.testDefaults = nil
        self.mockHistorical = nil
        self.mockAuth = nil
        try await super.tearDown()
    }

    // MARK: - Initial state

    func test_initialSyncStatus_isIdle() {
        XCTAssertEqual(
            self.sut.syncStatus,
            .idle,
            "syncStatus must start as .idle"
        )
    }

    // MARK: - Service call

    func test_performCloudSync_callsSyncToFirebase() async throws {
        self.sut.performCloudSync()
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)
        XCTAssertTrue(
            self.mockHistorical.syncToFirebaseCalled,
            "performCloudSync() must call historicalService.syncToFirebase()"
        )
    }

    // MARK: - Status transitions

    func test_performCloudSync_onSuccess_statusEventuallyReturnsToIdle() async throws {
        self.sut.performCloudSync()
        let settle = TimingConstants.syncSuccessDisplayNanoseconds + TimingConstants.testSettleDelayNanoseconds
        try await Task.sleep(nanoseconds: settle)
        XCTAssertEqual(
            self.sut.syncStatus,
            .idle,
            "syncStatus must return to .idle after a successful sync"
        )
    }

    func test_performCloudSync_onFailure_statusEventuallyReturnsToIdle() async throws {
        self.mockHistorical.syncToFirebaseShouldThrow = true
        self.sut.performCloudSync()
        let settle = TimingConstants.syncErrorDisplayNanoseconds + TimingConstants.testSettleDelayNanoseconds
        try await Task.sleep(nanoseconds: settle)
        XCTAssertEqual(
            self.sut.syncStatus,
            .idle,
            "syncStatus must return to .idle after a failed sync"
        )
    }

    // MARK: - Cancellation

    func test_cancelCloudSync_whenSyncing_setsStatusToIdle() {
        // Force syncStatus to .syncing before cancelling
        self.sut.syncStatus = .syncing
        self.sut.cancelCloudSync()
        XCTAssertEqual(
            self.sut.syncStatus,
            .idle,
            "cancelCloudSync() must set syncStatus to .idle when it was .syncing"
        )
    }

    func test_cancelCloudSync_whenNotSyncing_doesNotChangeStatus() {
        self.sut.syncStatus = .success
        self.sut.cancelCloudSync()
        XCTAssertEqual(
            self.sut.syncStatus,
            .success,
            "cancelCloudSync() must not alter syncStatus when not in .syncing state"
        )
    }

    // MARK: - Offline handling

    func test_performCloudSync_whenOffline_setsErrorStatus() async throws {
        self.sut.isNetworkAvailable = false
        self.sut.performCloudSync()
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)
        if case .error = self.sut.syncStatus {
            // Expected path
        } else {
            XCTFail("syncStatus must be .error when network is unavailable, got \(self.sut.syncStatus)")
        }
    }

    // MARK: - syncStatusText SSOT (Strings.Settings)

    func test_syncStatusText_idle_matchesStrings() {
        self.sut.syncStatus = .idle
        XCTAssertEqual(
            self.sut.syncStatusText,
            Strings.Settings.syncButtonIdle,
            "syncStatusText for .idle must equal Strings.Settings.syncButtonIdle"
        )
    }

    func test_syncStatusText_syncing_matchesStrings() {
        self.sut.syncStatus = .syncing
        XCTAssertEqual(
            self.sut.syncStatusText,
            Strings.Settings.syncButtonSyncing,
            "syncStatusText for .syncing must equal Strings.Settings.syncButtonSyncing"
        )
    }

    func test_syncStatusText_success_matchesStrings() {
        self.sut.syncStatus = .success
        XCTAssertEqual(
            self.sut.syncStatusText,
            Strings.Settings.syncButtonSuccess,
            "syncStatusText for .success must equal Strings.Settings.syncButtonSuccess"
        )
    }

    func test_syncStatusText_error_matchesStrings() {
        self.sut.syncStatus = .error("some error")
        XCTAssertEqual(
            self.sut.syncStatusText,
            Strings.Settings.syncButtonError,
            "syncStatusText for .error must equal Strings.Settings.syncButtonError"
        )
    }
}
