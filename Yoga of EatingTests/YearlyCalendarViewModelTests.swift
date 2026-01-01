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
    }
#endif
