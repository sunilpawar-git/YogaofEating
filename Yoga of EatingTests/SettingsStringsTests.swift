import XCTest
@testable import Yoga_of_Eating

/// SSOT coverage for Strings.Settings constants.
///
/// Each test asserts that a constant exists **and** holds its expected value.
/// A compile error here means the constant is missing from Strings.swift — the
/// Red phase in the TDD cycle. Once the constant is added the test turns Green.
@MainActor
final class SettingsStringsTests: XCTestCase {
    // MARK: - Navigation Title (Phase 6)

    /// `SettingsView` must use `Strings.Settings.navigationTitle` for its
    /// `navigationTitle(…)` modifier — never the hardcoded literal "Settings".
    func test_strings_navigationTitle_exists() {
        XCTAssertEqual(
            Strings.Settings.navigationTitle,
            "Settings",
            "Strings.Settings.navigationTitle must equal 'Settings'"
        )
    }

    // MARK: - Sign-in Button Title (Phase 6)

    /// The "Login with Google" button in the account section must use a Strings constant
    /// so the label has a single source of truth and is localization-ready.
    func test_strings_loginWithGoogleTitle_exists() {
        XCTAssertEqual(
            Strings.Settings.loginWithGoogleTitle,
            "Login with Google",
            "Strings.Settings.loginWithGoogleTitle must equal 'Login with Google'"
        )
    }

    // MARK: - Danger Zone (already in Strings — guard regressions)

    func test_strings_dangerZoneHeader_exists() {
        XCTAssertEqual(Strings.Settings.dangerZoneHeader, "Danger Zone")
    }

    func test_strings_clearAllDataTitle_exists() {
        XCTAssertEqual(Strings.Settings.clearAllDataTitle, "Clear All Data")
    }

    func test_strings_clearAllDataAlertTitle_exists() {
        XCTAssertEqual(Strings.Settings.clearAllDataAlertTitle, "Clear All Data?")
    }

    func test_strings_signOutTitle_exists() {
        XCTAssertEqual(Strings.Settings.signOutTitle, "Sign Out")
    }

    func test_strings_signOutAlertTitle_exists() {
        XCTAssertEqual(Strings.Settings.signOutAlertTitle, "Sign Out?")
    }

    // MARK: - Account / Navigation / History headers (Phase 6)

    func test_strings_accountHeader_exists() {
        XCTAssertEqual(Strings.Settings.accountHeader, "Account")
    }

    func test_strings_historyHeader_exists() {
        XCTAssertEqual(Strings.Settings.historyHeader, "History")
    }

    func test_strings_supportHeader_exists() {
        XCTAssertEqual(Strings.Settings.supportHeader, "Support & Legal")
    }

    // MARK: - Navigation section rows

    func test_strings_profileHealthTitle_exists() {
        XCTAssertEqual(Strings.Settings.profileHealthTitle, "Profile & Health")
    }

    func test_strings_preferencesTitle_exists() {
        XCTAssertEqual(Strings.Settings.preferencesTitle, "Preferences")
    }

    func test_strings_manageHealthAccessTitle_exists() {
        XCTAssertEqual(Strings.Settings.manageHealthAccessTitle, "Manage Health Access")
    }

    func test_strings_yearlyHeatmapTitle_exists() {
        XCTAssertEqual(Strings.Settings.yearlyHeatmapTitle, "Yearly Heatmap")
    }

    // MARK: - Sync / Restore labels (regression from Phase 5)

    func test_strings_syncButtonIdle_exists() {
        XCTAssertEqual(Strings.Settings.syncButtonIdle, "Sync with Cloud")
    }

    func test_strings_syncButtonSyncing_exists() {
        XCTAssertEqual(Strings.Settings.syncButtonSyncing, "Syncing...")
    }

    func test_strings_syncButtonSuccess_exists() {
        XCTAssertEqual(Strings.Settings.syncButtonSuccess, "Synced!")
    }

    func test_strings_syncButtonError_exists() {
        XCTAssertEqual(Strings.Settings.syncButtonError, "Sync Failed")
    }

    func test_strings_restoreButtonIdle_exists() {
        XCTAssertEqual(Strings.Settings.restoreButtonIdle, "Restore from Cloud")
    }

    // MARK: - Version / copyright footer functions

    func test_strings_versionFooter_format() {
        let result = Strings.Settings.versionFooter(version: "2.0", build: "99")
        XCTAssertEqual(result, "Yoga of Eating v2.0 (99)")
    }

    func test_strings_copyrightFooter_format() {
        let result = Strings.Settings.copyrightFooter(year: 2026)
        XCTAssertEqual(result, "© 2026 Sunil")
    }
}
