import XCTest
@testable import Yoga_of_Eating

/// SSOT coverage for Strings.Settings constants used in PreferencesSettingsView.
///
/// A compile error here means the constant is missing from Strings.swift — the
/// Red phase in the TDD cycle.
@MainActor
final class SettingsPreferencesStringsTests: XCTestCase {
    // MARK: - Navigation

    func test_preferencesTitle_exists() {
        XCTAssertEqual(Strings.Settings.preferencesTitle, "Preferences")
    }

    // MARK: - Appearance section

    func test_appearanceSectionHeader_exists() {
        XCTAssertEqual(Strings.Settings.appearanceSectionHeader, "Appearance")
    }

    func test_themeSystem_exists() {
        XCTAssertEqual(Strings.Settings.themeSystem, "System")
    }

    func test_themeLight_exists() {
        XCTAssertEqual(Strings.Settings.themeLight, "Light")
    }

    func test_themeDark_exists() {
        XCTAssertEqual(Strings.Settings.themeDark, "Dark")
    }

    func test_themeAccessibilityLabel_exists() {
        XCTAssertEqual(Strings.Settings.themeAccessibilityLabel, "Theme")
    }

    // MARK: - Notifications section

    func test_morningNudgeToggle_exists() {
        XCTAssertEqual(Strings.Settings.morningNudgeToggle, "Morning Nudge")
    }

    func test_mealRemindersToggle_exists() {
        XCTAssertEqual(Strings.Settings.mealRemindersToggle, "Meal Reminders")
    }

    func test_notificationsSectionHeader_exists() {
        XCTAssertEqual(Strings.Settings.notificationsSectionHeader, "Notifications")
    }

    // MARK: - Sensory Feedback section

    func test_sensoryFeedbackSectionHeader_exists() {
        XCTAssertEqual(Strings.Settings.sensoryFeedbackSectionHeader, "Sensory Feedback")
    }

    func test_hapticNudgesToggle_exists() {
        XCTAssertEqual(Strings.Settings.hapticNudgesToggle, "Haptic Nudges")
    }

    func test_soundEffectsToggle_exists() {
        XCTAssertEqual(Strings.Settings.soundEffectsToggle, "Sound Effects")
    }

    // MARK: - Integrations section

    func test_integrationsSectionHeader_exists() {
        XCTAssertEqual(Strings.Settings.integrationsSectionHeader, "Integrations")
    }

    func test_appleHealthToggle_exists() {
        XCTAssertEqual(Strings.Settings.appleHealthToggle, "Sync Body Metrics (Apple Health)")
    }

    func test_appleHealthFooter_exists() {
        XCTAssertEqual(
            Strings.Settings.appleHealthFooter,
            "When enabled, your height, weight, age, and gender will be synced from Apple Health."
        )
    }
}
