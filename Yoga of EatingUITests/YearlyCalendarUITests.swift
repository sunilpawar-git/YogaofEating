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
            let calendarHeader = self.app.staticTexts["Yearly Smiley Heatmap"]
            XCTAssertTrue(calendarHeader.exists, "Yearly Heatmap header should be visible")
        }

        func test_todayIsHighlighted() throws {
            // Navigate to calendar
            try self.test_navigatingToYearlyCalendar_fromSettings()

            // Check for today's cell highlight
            let todayCell = self.app.otherElements["heatmap-cell-today"]
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
    }
#endif
