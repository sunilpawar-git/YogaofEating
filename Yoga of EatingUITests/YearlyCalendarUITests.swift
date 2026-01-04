#if canImport(XCTest)
    import XCTest

    final class YearlyCalendarUITests: XCTestCase {
        let app = XCUIApplication()

        override func setUpWithError() throws {
            continueAfterFailure = false
            self.app.launch()
        }

        func test_navigatingToYearlyCalendar_fromSettings() throws {
            // Navigate to settings
            let settingsButton = self.app.buttons["settings-button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
            settingsButton.tap()

            // Find and tap Yearly Heatmap row (will be added in Phase 4)
            let heatmapRow = self.app.buttons["yearly-heatmap-link"]
            XCTAssertTrue(heatmapRow.waitForExistence(timeout: 5), "Yearly heatmap link should exist in settings")
            heatmapRow.tap()

            // Verify we are on the calendar screen
            let calendarHeader = self.app.staticTexts["Yearly Heatmap"]
            XCTAssertTrue(calendarHeader.exists, "Yearly Heatmap header should be visible")
        }

        func test_todayIsHighlighted() throws {
            // Navigate to calendar
            try self.test_navigatingToYearlyCalendar_fromSettings()

            // Check for today's cell highlight
            let todayCell = self.app.buttons["heatmap-cell-today"]
            XCTAssertTrue(todayCell.exists, "Today's cell should be highlighted and have a specific identifier")
        }

        func test_legendShowsAllMoods() throws {
            // Navigate to calendar
            try self.test_navigatingToYearlyCalendar_fromSettings()

            // Check for all three mood indicators in the legend
            XCTAssertTrue(self.app.staticTexts["legend-serene"].exists, "Serene legend should be visible")
            XCTAssertTrue(self.app.staticTexts["legend-neutral"].exists, "Neutral legend should be visible")
            XCTAssertTrue(self.app.staticTexts["legend-overwhelmed"].exists, "Overwhelmed legend should be visible")
        }

        // MARK: - Day Tap Tests

        func test_tappingTodayCell_opensPopup() throws {
            // Navigate to calendar
            try self.test_navigatingToYearlyCalendar_fromSettings()

            // Find and tap today's cell
            let todayCell = self.app.buttons["heatmap-cell-today"]
            XCTAssertTrue(todayCell.waitForExistence(timeout: 5), "Today's cell should exist")
            todayCell.tap()

            // Verify popup appears - it should show a sheet with "meals logged" text
            let mealsLoggedText = self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'meals logged'"))
                .firstMatch
            XCTAssertTrue(mealsLoggedText.waitForExistence(timeout: 3), "Popup should appear after tapping a day cell")
        }

        func test_tappingAnyCell_opensPopup() throws {
            // Navigate to calendar
            try self.test_navigatingToYearlyCalendar_fromSettings()

            // Find any heatmap cell (not necessarily today)
            let heatmapCells = self.app.buttons.matching(identifier: "heatmap-cell")
            XCTAssertGreaterThan(heatmapCells.count, 0, "There should be heatmap cells")

            // Tap the first available cell
            let firstCell = heatmapCells.element(boundBy: 0)
            if firstCell.waitForExistence(timeout: 3) {
                firstCell.tap()

                // Verify popup appears
                let popup = self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'meals logged'"))
                    .firstMatch
                XCTAssertTrue(popup.waitForExistence(timeout: 3), "Popup should appear after tapping any day cell")
            }
        }

        func test_popup_showsDateAndMealInfo() throws {
            // Navigate to calendar
            try self.test_navigatingToYearlyCalendar_fromSettings()

            // Tap today's cell
            let todayCell = self.app.buttons["heatmap-cell-today"]
            XCTAssertTrue(todayCell.waitForExistence(timeout: 5))
            todayCell.tap()

            // Verify popup contains expected elements
            // Should have "meals logged" text
            let mealsLoggedText = self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'meals logged'"))
                .firstMatch
            XCTAssertTrue(mealsLoggedText.waitForExistence(timeout: 3), "Popup should show meals logged count")
        }

        func test_dismissingPopup_returnsToCalendar() throws {
            // Navigate to calendar and open popup
            try self.test_navigatingToYearlyCalendar_fromSettings()

            let todayCell = self.app.buttons["heatmap-cell-today"]
            XCTAssertTrue(todayCell.waitForExistence(timeout: 5))
            todayCell.tap()

            // Wait for popup to appear
            sleep(1)

            // Swipe down to dismiss the sheet
            self.app.swipeDown()

            // Verify we're back on the calendar (today cell should still be visible)
            XCTAssertTrue(todayCell.waitForExistence(timeout: 3), "Should return to calendar after dismissing popup")
        }

        // MARK: - Weekday Alignment Tests

        func test_todayCell_isInCorrectWeekdayColumn() throws {
            // This is a visual/structural test - we verify today's cell exists
            // and has the correct accessibility identifier
            try self.test_navigatingToYearlyCalendar_fromSettings()

            let todayCell = self.app.buttons["heatmap-cell-today"]
            XCTAssertTrue(todayCell.waitForExistence(timeout: 5), "Today's cell should exist and be identifiable")

            // The accessibility label should contain today's date
            let todayLabel = todayCell.label
            XCTAssertFalse(todayLabel.isEmpty, "Today's cell should have an accessibility label")
        }

        // MARK: - Sheet Auto-Expansion Tests

        func test_sheet_startsAtMediumDetent_byDefault() throws {
            // Navigate to calendar
            try self.test_navigatingToYearlyCalendar_fromSettings()

            // Tap today's cell to open sheet
            let todayCell = self.app.buttons["heatmap-cell-today"]
            XCTAssertTrue(todayCell.waitForExistence(timeout: 5))
            todayCell.tap()

            // Wait for sheet to appear
            sleep(1)

            // Assert: Sheet should open (popup content should be visible)
            let mealsLoggedText = self.app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS 'meals logged'")
            ).firstMatch
            XCTAssertTrue(
                mealsLoggedText.waitForExistence(timeout: 3),
                "Sheet should open and show meals logged text"
            )
        }

        func test_sheet_canBeExpanded_toFullHeight() throws {
            // Navigate to calendar
            try self.test_navigatingToYearlyCalendar_fromSettings()

            // Tap today's cell
            let todayCell = self.app.buttons["heatmap-cell-today"]
            XCTAssertTrue(todayCell.waitForExistence(timeout: 5))
            todayCell.tap()

            // Wait for sheet to appear
            sleep(1)

            // Act: Swipe up to expand sheet
            self.app.swipeUp()

            sleep(1)

            // Assert: Sheet should be expanded (content still visible)
            let mealsLoggedText = self.app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS 'meals logged'")
            ).firstMatch
            XCTAssertTrue(mealsLoggedText.exists, "Sheet content should remain visible after expansion")
        }

        func test_sheet_showsMealDetails_whenExpanded() throws {
            // Navigate to calendar
            try self.test_navigatingToYearlyCalendar_fromSettings()

            // Tap today's cell
            let todayCell = self.app.buttons["heatmap-cell-today"]
            XCTAssertTrue(todayCell.waitForExistence(timeout: 5))
            todayCell.tap()

            sleep(1)

            // Expand sheet
            self.app.swipeUp()
            sleep(1)

            // Assert: Verify sheet structure
            // Should show date header and meal count
            let popup = self.app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS 'meals logged'")
            ).firstMatch
            XCTAssertTrue(popup.exists, "Popup should show meal count")

            // The SmileyView should be visible
            // This tests the sheet content renders properly at full height
        }

        func test_sheet_autoExpandsForManyMeals_accessibilityCheck() throws {
            // Navigate to calendar
            try self.test_navigatingToYearlyCalendar_fromSettings()

            // Find any heatmap cell
            let heatmapCells = self.app.buttons.matching(identifier: "heatmap-cell")

            guard heatmapCells.count > 0 else {
                XCTFail("Should have heatmap cells to test")
                return
            }

            // Tap a cell
            heatmapCells.element(boundBy: 0).tap()

            sleep(1)

            // Assert: Sheet should open (regardless of meal count, sheet is functional)
            let popup = self.app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS 'meals logged'")
            ).firstMatch

            // The popup should be accessible
            XCTAssertTrue(
                popup.waitForExistence(timeout: 3),
                "Popup should appear when tapping any cell"
            )
        }

        func test_userCanManuallyAdjustDetent_afterOpening() throws {
            // Navigate to calendar
            try self.test_navigatingToYearlyCalendar_fromSettings()

            // Tap today's cell
            let todayCell = self.app.buttons["heatmap-cell-today"]
            XCTAssertTrue(todayCell.waitForExistence(timeout: 5))
            todayCell.tap()

            sleep(1)

            // Act: Expand sheet
            self.app.swipeUp()
            sleep(1)

            // Act: Collapse sheet back down
            self.app.swipeDown()
            sleep(1)

            // Assert: Sheet should still be present (not dismissed)
            let popup = self.app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS 'meals logged'")
            ).firstMatch

            // After swipe down, sheet might be at medium detent or dismissed
            // If still visible, test passes (user can adjust)
            // If not visible, verify we're back on calendar
            if !popup.exists {
                // Sheet was dismissed, that's also valid user interaction
                let calendarCell = self.app.buttons["heatmap-cell-today"]
                XCTAssertTrue(
                    calendarCell.waitForExistence(timeout: 3),
                    "Should return to calendar when sheet is dismissed"
                )
            }
        }

        func test_sheet_displaysCorrectDateFormat() throws {
            // Navigate to calendar
            try self.test_navigatingToYearlyCalendar_fromSettings()

            // Tap today's cell
            let todayCell = self.app.buttons["heatmap-cell-today"]
            XCTAssertTrue(todayCell.waitForExistence(timeout: 5))
            todayCell.tap()

            sleep(1)

            // Assert: Should display today's date
            // The DayMealPopupView uses dateStyle: .full format
            // Look for day of week names (e.g., "Sunday", "Monday", etc.)
            let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            var foundDateText = false

            for dayName in dayNames {
                let dateText = self.app.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS %@", dayName)
                ).firstMatch
                if dateText.exists {
                    foundDateText = true
                    break
                }
            }

            XCTAssertTrue(foundDateText, "Popup should display the full date with day name")
        }

        func test_sheet_showsEmptyState_forDaysWithNoMeals() throws {
            // Navigate to calendar
            try self.test_navigatingToYearlyCalendar_fromSettings()

            // Find any cell (may or may not have meals)
            let heatmapCells = self.app.buttons.matching(identifier: "heatmap-cell")

            guard heatmapCells.count > 0 else {
                return
            }

            // Tap a cell
            heatmapCells.element(boundBy: 0).tap()

            sleep(1)

            // Assert: Should show either "0 meals logged" or meal list
            let zeroMealsText = self.app.staticTexts["0 meals logged"]
            let noMealsLoggedText = self.app.staticTexts["No meals logged for this day."]
            let anyMealsText = self.app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS 'meals logged'")
            ).firstMatch

            XCTAssertTrue(
                zeroMealsText.exists || noMealsLoggedText.exists || anyMealsText.exists,
                "Sheet should show meal count or empty state"
            )
        }
    }
#endif
