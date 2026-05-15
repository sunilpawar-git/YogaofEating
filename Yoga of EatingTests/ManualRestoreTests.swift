import XCTest
@testable import Yoga_of_Eating

// MARK: - ManualRestoreTests

/// Tests for the manual "Restore from Cloud" feature in Settings.
///
/// Edge case addressed: after `deleteAllData()`, `triggerCloudRestoreIfNeeded()` is blocked
/// by the `hasDeletedAllData` flag. The manual restore button must explicitly clear that flag
/// and then call `restoreFromFirebase()` so users can intentionally recover their cloud history.
@MainActor
final class ManualRestoreTests: XCTestCase {
    private var mockHistorical: MockHistoricalDataService!
    private var mockAuth: MockAuthService!
    private var testDefaults: UserDefaults!
    private var sut: SettingsViewModel!

    override func setUp() async throws {
        try await super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        self.mockAuth = MockAuthService()
        self.mockAuth.currentUser = MockAuthUser(uid: "u1", displayName: "Test", email: "test@test.com")
        // Isolated suite prevents UserDefaults pollution between tests
        self.testDefaults = UserDefaults(suiteName: "ManualRestoreTests.\(UUID().uuidString)")
        self.sut = SettingsViewModel(
            historicalService: self.mockHistorical,
            authService: self.mockAuth,
            userDefaults: self.testDefaults
        )
    }

    override func tearDown() async throws {
        self.sut = nil
        self.testDefaults = nil
        self.mockHistorical = nil
        self.mockAuth = nil
        try await super.tearDown()
    }

    // MARK: - Initial state

    func test_initialRestoreStatus_isIdle() {
        XCTAssertEqual(
            self.sut.restoreStatus,
            .idle,
            "restoreStatus must start as .idle"
        )
    }

    // MARK: - Flag management

    func test_performCloudRestore_clearsDeletionFlag_beforeRestore() {
        self.testDefaults.set(true, forKey: StorageKeys.hasDeletedAllData)
        // Flag must be cleared synchronously before the async Task launches
        self.sut.performCloudRestore()
        XCTAssertFalse(
            self.testDefaults.bool(forKey: StorageKeys.hasDeletedAllData),
            "performCloudRestore() must clear hasDeletedAllData synchronously before launching restore"
        )
    }

    func test_performCloudRestore_whenFlagNotSet_doesNotSetIt() {
        // Ensure calling restore when flag was never set doesn't accidentally set it
        self.sut.performCloudRestore()
        XCTAssertFalse(
            self.testDefaults.bool(forKey: StorageKeys.hasDeletedAllData),
            "performCloudRestore() must not set hasDeletedAllData"
        )
    }

    // MARK: - Service call

    func test_performCloudRestore_callsRestoreFromFirebase() async throws {
        self.sut.performCloudRestore()
        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)
        XCTAssertTrue(
            self.mockHistorical.restoreFromFirebaseCalled,
            "performCloudRestore() must call historicalService.restoreFromFirebase()"
        )
    }

    // MARK: - Status transitions

    func test_performCloudRestore_onSuccess_statusEventuallyReturnsToIdle() async throws {
        self.sut.performCloudRestore()
        // Allow full success → auto-idle transition to settle
        let longerSettle = TimingConstants.syncSuccessDisplayNanoseconds + TimingConstants.testSettleDelayNanoseconds
        try await Task.sleep(nanoseconds: longerSettle)
        XCTAssertEqual(
            self.sut.restoreStatus,
            .idle,
            "restoreStatus must return to .idle after a successful restore"
        )
    }

    func test_performCloudRestore_onFailure_statusEventuallyReturnsToIdle() async throws {
        self.mockHistorical.restoreFromFirebaseShouldThrow = true
        self.sut.performCloudRestore()
        let longerSettle = TimingConstants.syncErrorDisplayNanoseconds + TimingConstants.testSettleDelayNanoseconds
        try await Task.sleep(nanoseconds: longerSettle)
        XCTAssertEqual(
            self.sut.restoreStatus,
            .idle,
            "restoreStatus must return to .idle after a failed restore"
        )
    }

    // MARK: - restoreStatusText — SSOT from Strings.Settings

    func test_restoreStatusText_idle_matchesStrings() {
        self.sut.restoreStatus = .idle
        XCTAssertEqual(
            self.sut.restoreStatusText,
            Strings.Settings.restoreButtonIdle,
            "restoreStatusText for .idle must equal Strings.Settings.restoreButtonIdle"
        )
    }

    func test_restoreStatusText_restoring_matchesStrings() {
        self.sut.restoreStatus = .restoring
        XCTAssertEqual(
            self.sut.restoreStatusText,
            Strings.Settings.restoreButtonRestoring,
            "restoreStatusText for .restoring must equal Strings.Settings.restoreButtonRestoring"
        )
    }

    func test_restoreStatusText_success_matchesStrings() {
        self.sut.restoreStatus = .success
        XCTAssertEqual(
            self.sut.restoreStatusText,
            Strings.Settings.restoreButtonSuccess,
            "restoreStatusText for .success must equal Strings.Settings.restoreButtonSuccess"
        )
    }

    func test_restoreStatusText_error_matchesStrings() {
        self.sut.restoreStatus = .error("some error")
        XCTAssertEqual(
            self.sut.restoreStatusText,
            Strings.Settings.restoreButtonError,
            "restoreStatusText for .error must equal Strings.Settings.restoreButtonError"
        )
    }
}
