#if canImport(XCTest)
    import XCTest

    /// UI tests for the Preferences settings screen (toggles, morning-briefing time picker).
    /// Extracted from SettingsUITests (Phase 7) to honour the 300-line file limit.
    @MainActor
    final class SettingsPreferencesUITests: XCTestCase {
        var app: XCUIApplication!

        override func setUpWithError() throws {
            continueAfterFailure = false
            self.app = XCUIApplication()
            self.app.launchArguments = ["--uitesting"]
            self.app.launch()
        }

        override func tearDownWithError() throws {
            self.app = nil
        }

        // MARK: - Morning Briefing Time Picker

        func test_preferences_morningTimePicker_hasAccessibilityIdentifier() throws {
            try self.openPreferences()

            let nudgeToggle = self.app.switches["morning-nudge-toggle"]
            XCTAssertTrue(nudgeToggle.waitForExistence(timeout: 5))

            // Ensure nudge is ON before looking for the picker
            if nudgeToggle.value as? String == "0" {
                nudgeToggle.tap()
                sleep(1)
            }

            let picker = self.app.datePickers["morning-briefing-time-picker"]
            XCTAssertTrue(
                picker.waitForExistence(timeout: 3),
                "DatePicker must be accessible via 'morning-briefing-time-picker' identifier"
            )
        }

        func test_preferences_morningTimePicker_hiddenWhenNudgeDisabled() throws {
            try self.openPreferences()

            let nudgeToggle = self.app.switches["morning-nudge-toggle"]
            XCTAssertTrue(nudgeToggle.waitForExistence(timeout: 5))

            // iOS 16+ SwiftUI Form: use coordinate tap so UITouch propagates correctly.
            let tapCoord = nudgeToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))

            // Default isMorningNudgeEnabled is true — toggle starts ON.
            if nudgeToggle.value as? String == "1" {
                tapCoord.tap()
                sleep(1)
            }

            let picker = self.app.datePickers["morning-briefing-time-picker"]
            XCTAssertTrue(
                picker.waitForNonExistence(timeout: 5),
                "Time picker must be hidden when morning nudge is disabled"
            )
        }

        func test_preferences_morningTimePicker_visibleWhenNudgeEnabled() throws {
            try self.openPreferences()

            let nudgeToggle = self.app.switches["morning-nudge-toggle"]
            XCTAssertTrue(nudgeToggle.waitForExistence(timeout: 5))

            if nudgeToggle.value as? String == "0" {
                nudgeToggle.tap()
                sleep(1)
            }

            let picker = self.app.datePickers["morning-briefing-time-picker"]
            XCTAssertTrue(
                picker.waitForExistence(timeout: 3),
                "Time picker must appear when morning nudge is enabled"
            )
        }

        // MARK: - Helpers

        private func openPreferences() throws {
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()
            sleep(1)

            // Strategy 1: find by accessibility identifier (fastest)
            var preferencesRow = self.app.descendants(matching: .any)
                .matching(identifier: "preferences-settings-link").firstMatch

            // Strategy 2: fall back to the visible "Preferences" button label
            if !preferencesRow.waitForExistence(timeout: 2) {
                preferencesRow = self.app.buttons
                    .matching(NSPredicate(format: "label == 'Preferences'")).firstMatch
            }

            // Strategy 3: swipe and retry if still not found
            if !preferencesRow.waitForExistence(timeout: 2) {
                self.app.swipeUp(velocity: .slow)
                sleep(1)
                preferencesRow = self.app.buttons
                    .matching(NSPredicate(format: "label == 'Preferences'")).firstMatch
            }

            XCTAssertTrue(
                preferencesRow.waitForExistence(timeout: 5),
                "Preferences row must be visible in Settings (tried identifier + label + scroll)"
            )
            preferencesRow.tap()
            sleep(1)
        }
    }
#endif
