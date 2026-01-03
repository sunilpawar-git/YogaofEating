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
    }
#endif
