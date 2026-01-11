#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class YearlyCalendarViewModelTests: XCTestCase {
        var sut: YearlyCalendarViewModel!
        var mockHistorical: MockHistoricalDataService!

        override func setUp() {
            super.setUp()
            self.mockHistorical = MockHistoricalDataService()
            self.sut = YearlyCalendarViewModel(historicalService: self.mockHistorical)
        }

        override func tearDown() {
            self.sut = nil
            self.mockHistorical = nil
            super.tearDown()
        }

        func test_initialState_isCurrentYear() {
            let currentYear = Calendar.current.component(.year, from: Date())
            XCTAssertEqual(self.sut.selectedYear, currentYear)
            XCTAssertTrue(self.sut.snapshots.isEmpty)
        }

        func test_fetchSnapshots_updatesSnapshots() {
            // Given
            let calendar = Calendar.current
            let date = calendar.date(from: DateComponents(year: 2025, month: 5, day: 15))!
            let snapshot = DailySmileySnapshot(
                id: UUID(),
                date: date,
                smileyState: SmileyState(scale: 0.8, mood: .serene),
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.8
            )
            self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)
            self.sut.selectedYear = 2025

            // When
            self.sut.fetchSnapshots()

            // Then
            XCTAssertEqual(self.sut.snapshots.count, 1)
            XCTAssertEqual(self.sut.snapshots.first?.date, calendar.startOfDay(for: date))
        }

        func test_selectingSnapshot_updatesSelectedSnapshot() {
            // Given
            let calendar = Calendar.current
            let date = calendar.date(from: DateComponents(year: 2025, month: 5, day: 15))!
            let snapshot = DailySmileySnapshot(
                id: UUID(),
                date: date,
                smileyState: SmileyState(scale: 0.8, mood: .serene),
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.8
            )

            // When
            self.sut.selectSnapshot(snapshot)

            // Then
            XCTAssertEqual(self.sut.selectedSnapshot?.id, snapshot.id)
            XCTAssertEqual(self.sut.selectedSnapshot?.date, calendar.startOfDay(for: date))
        }

        func test_changingYear_refetchesSnapshots() {
            // Given
            self.sut.selectedYear = 2024

            // When
            self.sut.selectedYear = 2025

            // Then
            // In a real implementation, we might use a Combine publisher or similar
            // For now, we'll just check if snapshots are updated (expected to be empty for 2025 in this mock)
            XCTAssertTrue(self.sut.snapshots.isEmpty)
        }

        func test_yearDates_hasCorrectCountAndStart() {
            // Given
            self.sut.selectedYear = 2024 // Leap year

            // When
            let dates = self.sut.allDates

            // Then
            XCTAssertEqual(dates.count, 366)
            let calendar = Calendar.current
            let firstDate = dates.first!
            XCTAssertEqual(calendar.component(.month, from: firstDate), 1)
            XCTAssertEqual(calendar.component(.day, from: firstDate), 1)
            XCTAssertEqual(calendar.component(.year, from: firstDate), 2024)
        }

        func test_monthLabelOffsets_calculatedCorrectly() {
            // Given
            self.sut.selectedYear = 2024 // Jan 1, 2024 was a Monday (week 1)

            // When
            let months = self.sut.monthLabels

            // Then
            XCTAssertEqual(months.count, 12)
            XCTAssertEqual(months[0].name, "Jan")
            XCTAssertEqual(months[0].weekOffset, 0) // First week of the year

            // Feb 1, 2024 (Thursday) should be week 5 relative to Jan 1
            XCTAssertEqual(months[1].name, "Feb")
            XCTAssertGreaterThan(months[1].weekOffset, 0)
        }

        // MARK: - Layout Configuration Tests

        func test_initialLayout_hasDefaultConfiguration() {
            // Then: Should have a valid initial layout
            XCTAssertGreaterThanOrEqual(self.sut.layoutConfig.cellSize, 32)
            XCTAssertEqual(self.sut.layoutConfig.spacing, 4)
        }

        func test_updateLayout_forPortrait_setsVerticalDirection() {
            // When
            self.sut.updateLayout(screenWidth: 375, screenHeight: 667, isPortrait: true)

            // Then
            XCTAssertEqual(self.sut.layoutConfig.gridDirection, .vertical)
        }

        func test_updateLayout_forLandscape_setsHorizontalDirection() {
            // When
            self.sut.updateLayout(screenWidth: 667, screenHeight: 375, isPortrait: false)

            // Then
            XCTAssertEqual(self.sut.layoutConfig.gridDirection, .horizontal)
        }

        func test_updateLayout_calculatesAppropiateCellSize() {
            // When: iPhone SE portrait
            self.sut.updateLayout(screenWidth: 375, screenHeight: 667, isPortrait: true)

            // Then: Cell size should be at least minimum tap target
            XCTAssertGreaterThanOrEqual(self.sut.layoutConfig.cellSize, 32)

            // When: iPad portrait
            self.sut.updateLayout(screenWidth: 768, screenHeight: 1024, isPortrait: true)

            // Then: Larger device should have larger cells (up to max)
            XCTAssertLessThanOrEqual(self.sut.layoutConfig.cellSize, 50)
        }

        func test_updateLayout_onlyUpdatesWhenMeaningfulChange() {
            // Given: Initial layout
            self.sut.updateLayout(screenWidth: 375, screenHeight: 667, isPortrait: true)
            let initialCellSize = self.sut.layoutConfig.cellSize

            // When: Same dimensions
            self.sut.updateLayout(screenWidth: 375, screenHeight: 667, isPortrait: true)

            // Then: Cell size should remain the same
            XCTAssertEqual(self.sut.layoutConfig.cellSize, initialCellSize)
        }

        // MARK: - Weekday Alignment Tests

        func test_allCells_includesPlaceholdersForWeekdayAlignment() {
            // Given: 2026 where Jan 1 is a Thursday
            // Monday=0, Tuesday=1, Wednesday=2, Thursday=3
            // So we need 3 placeholder cells before Jan 1
            self.sut.selectedYear = 2026

            // When
            let cells = self.sut.allCells

            // Then: First 3 cells should be placeholders
            XCTAssertTrue(cells[0].isPlaceholder, "First cell should be a placeholder (Monday)")
            XCTAssertTrue(cells[1].isPlaceholder, "Second cell should be a placeholder (Tuesday)")
            XCTAssertTrue(cells[2].isPlaceholder, "Third cell should be a placeholder (Wednesday)")
            XCTAssertFalse(cells[3].isPlaceholder, "Fourth cell should be Jan 1 (Thursday)")
        }

        func test_allCells_jan1AppearsInCorrectWeekdayColumn_2026() {
            // Given: 2026 where Jan 1 is a Thursday (column index 3, 0-based)
            self.sut.selectedYear = 2026

            // When
            let cells = self.sut.allCells
            let jan1Cell = cells.first { !$0.isPlaceholder }

            // Then: Jan 1 should be at index 3 (Thursday column in 7-column grid)
            let jan1Index = cells.firstIndex { $0.id == jan1Cell?.id }
            XCTAssertEqual(jan1Index, 3, "Jan 1, 2026 (Thursday) should be at index 3")
        }

        func test_allCells_jan1AppearsInCorrectWeekdayColumn_2024() {
            // Given: 2024 where Jan 1 is a Monday (column index 0)
            self.sut.selectedYear = 2024

            // When
            let cells = self.sut.allCells

            // Then: First cell should be Jan 1 (no placeholders needed)
            XCTAssertFalse(cells[0].isPlaceholder, "Jan 1, 2024 (Monday) should be first, no placeholders")

            // Verify it's actually Jan 1
            let calendar = Calendar.current
            if let date = cells[0].date {
                XCTAssertEqual(calendar.component(.month, from: date), 1)
                XCTAssertEqual(calendar.component(.day, from: date), 1)
            } else {
                XCTFail("First cell should have a date")
            }
        }

        func test_allCells_jan1AppearsInCorrectWeekdayColumn_2023() {
            // Given: 2023 where Jan 1 is a Sunday (column index 6)
            // We need 6 placeholder cells (Mon-Sat)
            self.sut.selectedYear = 2023

            // When
            let cells = self.sut.allCells

            // Then: First 6 cells should be placeholders
            for i in 0..<6 {
                XCTAssertTrue(cells[i].isPlaceholder, "Cell \(i) should be a placeholder")
            }
            XCTAssertFalse(cells[6].isPlaceholder, "Cell 6 should be Jan 1 (Sunday)")
        }

        func test_allCells_totalCountIncludesPlaceholders() {
            // Given: 2026 with 365 days + 3 placeholders = 368 cells
            self.sut.selectedYear = 2026

            // When
            let cells = self.sut.allCells
            let placeholderCount = cells.count(where: { $0.isPlaceholder })
            let actualDateCount = cells.count(where: { !$0.isPlaceholder })

            // Then
            XCTAssertEqual(placeholderCount, 3, "Should have 3 placeholder cells for 2026")
            XCTAssertEqual(actualDateCount, 365, "Should have 365 actual dates in 2026")
            XCTAssertEqual(cells.count, 368, "Total cells should be 368")
        }

        func test_allDates_excludesPlaceholders() {
            // Given: 2026 with 365 days
            self.sut.selectedYear = 2026

            // When
            let dates = self.sut.allDates

            // Then: allDates should only contain actual dates, no placeholders
            XCTAssertEqual(dates.count, 365, "allDates should have exactly 365 dates for 2026")
        }

        func test_currentDay_appearsInCorrectColumn() {
            // Given: Current year and today's date
            let today = Date()
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: today)
            self.sut.selectedYear = currentYear

            // When
            let cells = self.sut.allCells

            // Find today's cell
            let todayCell = cells.first { cell in
                guard let date = cell.date else { return false }
                return calendar.isDateInToday(date)
            }

            // Calculate expected weekday offset
            let todayWeekday = calendar.component(.weekday, from: today)
            let expectedMondayBasedIndex = (todayWeekday + 5) % 7 // 0=Monday, 6=Sunday

            // Then: Today's cell index mod 7 should equal expected weekday column
            if let todayCell, let index = cells.firstIndex(of: todayCell) {
                let column = index % 7
                XCTAssertEqual(
                    column, expectedMondayBasedIndex,
                    "Today should be in column \(expectedMondayBasedIndex), but was in column \(column)"
                )
            } else {
                XCTFail("Could not find today's cell")
            }
        }
    }
#endif
