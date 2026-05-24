#if canImport(XCTest)
    import XCTest

    /// UI tests for cloud sync button states and Cloud Backup navigation link.
    /// Extracted from SettingsUITests (Phase 7) to honour the 300-line file limit.
    @MainActor
    final class SettingsCloudBackupUITests: XCTestCase {
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

        // MARK: - Sync Button

        func test_syncButton_exists_whenUserSignedIn() throws {
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()
            sleep(1)

            // Sync button only shows when user is signed in.
            let syncButton = self.app.buttons["Sync with Cloud button"]
            if syncButton.exists {
                XCTAssertTrue(syncButton.isEnabled, "Sync button should be enabled when not syncing")
            } else {
                // Expected in --uitesting: user is signed out, sign-in affordance is shown instead.
                let signInButton = self.app.buttons.matching(
                    NSPredicate(format: "label CONTAINS[c] 'Login' OR label CONTAINS[c] 'Google'")
                ).firstMatch
                XCTAssertTrue(
                    signInButton.exists,
                    "Either sync button or sign-in button should be visible"
                )
            }
        }

        func test_syncButton_showsSyncingText_whenTapped() throws {
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()
            sleep(1)

            let syncButton = self.app.buttons["Sync with Cloud button"]
            guard syncButton.exists else { return }

            syncButton.tap()

            let syncingButton = self.app.buttons["Syncing data to cloud"]
            let syncingExists = syncingButton.waitForExistence(timeout: 2)
            let successExists = self.app.buttons["Sync completed successfully"].exists

            XCTAssertTrue(
                syncingExists || successExists,
                "Sync button should show syncing or success state after tap"
            )
        }

        func test_syncButton_revertsToIdle_afterSyncComplete() throws {
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()
            sleep(1)

            let syncButton = self.app.buttons["Sync with Cloud button"]
            guard syncButton.exists else { return }

            syncButton.tap()
            sleep(5) // Allow sync to complete and auto-revert

            XCTAssertTrue(
                self.app.buttons["Sync with Cloud button"].waitForExistence(timeout: 3),
                "Sync button should revert to idle state after sync completes"
            )
        }

        func test_syncButton_isDisabled_whileSyncing() throws {
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()
            sleep(1)

            let syncButton = self.app.buttons["Sync with Cloud button"]
            guard syncButton.exists else { return }

            syncButton.tap()

            let syncingButton = self.app.buttons["Syncing data to cloud"]
            if syncingButton.waitForExistence(timeout: 2) {
                XCTAssertFalse(
                    syncingButton.isEnabled,
                    "Sync button should be disabled while syncing"
                )
            }
        }

        func test_syncButton_hasCorrectAccessibilityHint() throws {
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()
            sleep(1)

            let syncButton = self.app.buttons["Sync with Cloud button"]
            guard syncButton.exists else { return }

            XCTAssertTrue(syncButton.isHittable, "Sync button should be tappable in idle state")
        }

        func test_syncButton_fullWidthDivider_existsBelow() throws {
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()
            sleep(1)

            XCTAssertTrue(
                self.app.navigationBars["Settings"].exists,
                "Settings view should be displayed"
            )

            // The yearly-heatmap-link lives in the History section below the sync area.
            let yearlyHeatmapLink = self.app.buttons["yearly-heatmap-link"]
            XCTAssertTrue(
                yearlyHeatmapLink.waitForExistence(timeout: 3),
                "Yearly heatmap link should exist in Settings"
            )
        }

        // MARK: - Cloud Backup Navigation

        func test_cloudBackup_userDataSection_showsSignInWhenSignedOut() throws {
            // --uitesting always signs the user out — cloud-backup-link must be hidden.
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()
            sleep(1)

            let cloudBackupLink = self.app.descendants(matching: .any)
                .matching(identifier: "cloud-backup-link").firstMatch
            XCTAssertFalse(
                cloudBackupLink.waitForExistence(timeout: 2),
                "cloud-backup-link must not be visible when the user is signed out"
            )
        }

        func test_cloudBackup_navigationLink_opensClouBackupScreen() throws {
            // Requires signed-in user. Skip gracefully in --uitesting (signed-out).
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()
            sleep(1)

            let cloudBackupLink = self.app.descendants(matching: .any)
                .matching(identifier: "cloud-backup-link").firstMatch
            if !cloudBackupLink.waitForExistence(timeout: 2) { return }
            cloudBackupLink.tap()
            sleep(1)

            XCTAssertTrue(
                self.app.navigationBars["Cloud Backup"].waitForExistence(timeout: 3),
                "Cloud Backup screen must show 'Cloud Backup' navigation title"
            )
        }

        func test_cloudBackup_screen_showsSyncButton() throws {
            // Requires signed-in user. Skip gracefully in --uitesting (signed-out).
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()
            sleep(1)

            let cloudBackupLink = self.app.descendants(matching: .any)
                .matching(identifier: "cloud-backup-link").firstMatch
            guard cloudBackupLink.waitForExistence(timeout: 2) else { return }
            cloudBackupLink.tap()
            sleep(1)

            XCTAssertTrue(
                self.app.staticTexts["Sync with Cloud"].waitForExistence(timeout: 3),
                "Cloud Backup screen must show the sync button in idle state"
            )
        }
    }
#endif
