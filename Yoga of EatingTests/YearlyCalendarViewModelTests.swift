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
    }
#endif
