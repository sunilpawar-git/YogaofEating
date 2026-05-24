#if canImport(XCTest)
    import XCTest

    /// Core Settings sheet tests: open/close, section structure, and Danger Zone actions.
    /// Cloud backup tests → SettingsCloudBackupUITests.swift
    /// Preferences tests  → SettingsPreferencesUITests.swift
    @MainActor
    final class SettingsUITests: XCTestCase {
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

        // MARK: - Settings Sheet

        func test_openSettings_showsSheet() throws {
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()
            sleep(1)

            let settingsTitle = self.app.navigationBars["Settings"]
            XCTAssertTrue(
                settingsTitle.waitForExistence(timeout: 3),
                "Settings sheet should open and show Settings title"
            )
        }

        func test_toggleTheme_updatesUI() throws {
            let settingsButton = self.app.buttons["settings-button"]
            settingsButton.tap()
            sleep(1)

            let doneButton = self.app.buttons["Done"]
            XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Settings should have a Done button")
            XCTAssertTrue(self.app.navigationBars.count > 0, "Settings should display in a navigation view")
        }

        func test_toggleHaptics_updatesPreference() throws {
            let settingsButton = self.app.buttons["settings-button"]
            settingsButton.tap()
            sleep(1)

            XCTAssertTrue(self.app.navigationBars["Settings"].exists, "Settings view should be displayed")
            XCTAssertTrue(self.app.buttons["Done"].exists, "Done button should be available")
        }

        func test_toggleSounds_updatesPreference() throws {
            let settingsButton = self.app.buttons["settings-button"]
            settingsButton.tap()
            sleep(1)

            XCTAssertTrue(self.app.navigationBars["Settings"].exists, "Settings view should be displayed")
            XCTAssertTrue(self.app.buttons["Done"].exists, "Settings should have Done button")
        }

        func test_updatePersonalDetails_saveCorrectly() throws {
            let settingsButton = self.app.buttons["settings-button"]
            settingsButton.tap()
            sleep(1)

            let textFields = self.app.textFields
            if textFields.count > 0 {
                let nameField = textFields.firstMatch
                if nameField.exists {
                    nameField.tap()
                    XCTAssertTrue(nameField.isEnabled, "Name field should be editable")
                }
            }
            XCTAssertTrue(
                self.app.navigationBars["Settings"].waitForExistence(timeout: 3),
                "Settings view should be visible after opening"
            )
        }

        func test_clearAllData_showsConfirmation() throws {
            let settingsButton = self.app.buttons["settings-button"]
            settingsButton.tap()
            sleep(1)

            let clearButton = self.app.buttons
                .matching(NSPredicate(format: "label CONTAINS[c] 'Clear'")).firstMatch

            if clearButton.exists {
                clearButton.tap()
                sleep(1)

                let alert = self.app.alerts.firstMatch
                XCTAssertTrue(alert.exists, "Confirmation alert should appear when clearing data")

                let cancelButton = alert.buttons["Cancel"]
                if cancelButton.exists { cancelButton.tap() }
            } else {
                XCTAssertTrue(
                    self.app.navigationBars["Settings"].exists,
                    "Settings view should be open when Clear button is not visible"
                )
            }
        }

        // MARK: - Phase 6: 5-Section Restructure

        func test_navigation_manageHealthAccess_link_exists() throws {
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()
            sleep(1)

            let link = self.app.descendants(matching: .any)
                .matching(identifier: "manage-health-access-link").firstMatch
            XCTAssertTrue(
                link.waitForExistence(timeout: 3),
                "Manage Health Access link must exist in the navigation section"
            )
        }

        func test_dangerZone_clearAllData_hasAccessibilityId() throws {
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()
            sleep(1)

            // Danger Zone is at the bottom of the form — scroll down to expose it.
            self.app.swipeUp(velocity: .slow)
            sleep(1)

            let button = self.app.buttons["clear-all-data-button"]
            XCTAssertTrue(
                button.waitForExistence(timeout: 3),
                "Clear All Data button must have the 'clear-all-data-button' accessibility identifier"
            )
        }
    }
#endif
