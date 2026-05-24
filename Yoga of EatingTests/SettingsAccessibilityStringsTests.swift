import XCTest
@testable import Yoga_of_Eating

/// SSOT coverage for accessibility strings used in SettingsViewModel+Sync and
/// SettingsViewModel+Restore.
///
/// Each test asserts that a constant exists and holds the exact value that
/// XCUITest queries reference (e.g., `app.buttons["Sync with Cloud button"]`).
/// A compile error here means the constant is missing from Strings.swift — the
/// Red phase in the TDD cycle.
@MainActor
final class SettingsAccessibilityStringsTests: XCTestCase {
    // MARK: - Sync accessibility labels

    func test_syncAccessibilityLabelIdle_exists() {
        XCTAssertEqual(
            Strings.Settings.syncAccessibilityLabelIdle,
            "Sync with Cloud button"
        )
    }

    func test_syncAccessibilityLabelSyncing_exists() {
        XCTAssertEqual(
            Strings.Settings.syncAccessibilityLabelSyncing,
            "Syncing data to cloud"
        )
    }

    func test_syncAccessibilityLabelSuccess_exists() {
        XCTAssertEqual(
            Strings.Settings.syncAccessibilityLabelSuccess,
            "Sync completed successfully"
        )
    }

    func test_syncAccessibilityLabelErrorPrefix_exists() {
        XCTAssertEqual(
            Strings.Settings.syncAccessibilityLabelErrorPrefix,
            "Sync failed: "
        )
    }

    // MARK: - Sync accessibility hints

    func test_syncAccessibilityHintIdle_exists() {
        XCTAssertEqual(
            Strings.Settings.syncAccessibilityHintIdle,
            "Double tap to sync your data with cloud storage"
        )
    }

    func test_syncAccessibilityHintSyncing_exists() {
        XCTAssertEqual(
            Strings.Settings.syncAccessibilityHintSyncing,
            "Sync in progress, please wait"
        )
    }

    func test_syncAccessibilityHintSuccess_exists() {
        XCTAssertEqual(
            Strings.Settings.syncAccessibilityHintSuccess,
            "Sync completed"
        )
    }

    func test_syncAccessibilityHintError_exists() {
        XCTAssertEqual(
            Strings.Settings.syncAccessibilityHintError,
            "Double tap to retry sync"
        )
    }

    // MARK: - Restore accessibility labels

    func test_restoreAccessibilityLabelIdle_exists() {
        XCTAssertEqual(
            Strings.Settings.restoreAccessibilityLabelIdle,
            "Restore from Cloud button"
        )
    }

    func test_restoreAccessibilityLabelRestoring_exists() {
        XCTAssertEqual(
            Strings.Settings.restoreAccessibilityLabelRestoring,
            "Restoring data from cloud"
        )
    }

    func test_restoreAccessibilityLabelSuccess_exists() {
        XCTAssertEqual(
            Strings.Settings.restoreAccessibilityLabelSuccess,
            "Restore completed successfully"
        )
    }

    func test_restoreAccessibilityLabelErrorPrefix_exists() {
        XCTAssertEqual(
            Strings.Settings.restoreAccessibilityLabelErrorPrefix,
            "Restore failed: "
        )
    }

    // MARK: - Restore accessibility hints

    func test_restoreAccessibilityHintIdle_exists() {
        XCTAssertEqual(
            Strings.Settings.restoreAccessibilityHintIdle,
            "Double tap to restore your meal history from cloud storage"
        )
    }

    func test_restoreAccessibilityHintRestoring_exists() {
        XCTAssertEqual(
            Strings.Settings.restoreAccessibilityHintRestoring,
            "Restore in progress, please wait"
        )
    }

    func test_restoreAccessibilityHintSuccess_exists() {
        XCTAssertEqual(
            Strings.Settings.restoreAccessibilityHintSuccess,
            "Restore completed"
        )
    }

    func test_restoreAccessibilityHintError_exists() {
        XCTAssertEqual(
            Strings.Settings.restoreAccessibilityHintError,
            "Double tap to retry restore"
        )
    }

    // MARK: - ViewModel integration: syncAccessibilityLabel uses constants

    func test_syncAccessibilityLabel_idle_matchesStringConstant() {
        let viewModel = SettingsViewModel(
            historicalService: MockHistoricalDataService(),
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!
        )
        // syncStatus defaults to .idle
        XCTAssertEqual(
            viewModel.syncAccessibilityLabel,
            Strings.Settings.syncAccessibilityLabelIdle
        )
    }

    func test_syncAccessibilityLabel_success_matchesStringConstant() {
        let viewModel = SettingsViewModel(
            historicalService: MockHistoricalDataService(),
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!
        )
        viewModel.syncStatus = .success
        XCTAssertEqual(
            viewModel.syncAccessibilityLabel,
            Strings.Settings.syncAccessibilityLabelSuccess
        )
    }

    func test_syncAccessibilityHint_idle_matchesStringConstant() {
        let viewModel = SettingsViewModel(
            historicalService: MockHistoricalDataService(),
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!
        )
        XCTAssertEqual(
            viewModel.syncAccessibilityHint,
            Strings.Settings.syncAccessibilityHintIdle
        )
    }

    // MARK: - ViewModel integration: restoreAccessibilityLabel uses constants

    func test_restoreAccessibilityLabel_idle_matchesStringConstant() {
        let viewModel = SettingsViewModel(
            historicalService: MockHistoricalDataService(),
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!
        )
        XCTAssertEqual(
            viewModel.restoreAccessibilityLabel,
            Strings.Settings.restoreAccessibilityLabelIdle
        )
    }

    func test_restoreAccessibilityHint_idle_matchesStringConstant() {
        let viewModel = SettingsViewModel(
            historicalService: MockHistoricalDataService(),
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!
        )
        XCTAssertEqual(
            viewModel.restoreAccessibilityHint,
            Strings.Settings.restoreAccessibilityHintIdle
        )
    }
}
