// swiftlint:disable force_unwrapping file_length
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for day navigation functionality
    /// Phase 4: TDD - Tests written before implementation
    @MainActor
    final class DayNavigationTests: XCTestCase {
        // MARK: - Properties

        var sut: MainViewModel!
        var mockLogic: MockMealLogicService!
        var mockPersistence: MockPersistenceService!
        var mockHistorical: MockHistoricalDataService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.mockLogic = MockMealLogicService()
            self.mockPersistence = MockPersistenceService()
            self.mockHistorical = MockHistoricalDataService()
            self.sut = MainViewModel(
                logicService: self.mockLogic,
                persistenceService: self.mockPersistence,
                historicalService: self.mockHistorical
            )
        }

        override func tearDown() {
            self.sut = nil
            self.mockLogic = nil
            self.mockPersistence = nil
            self.mockHistorical = nil
            super.tearDown()
        }

        // MARK: - Helper Methods

        private func createHistoricalSnapshot(daysAgo: Int, mealCount: Int = 2) -> DailySmileySnapshot {
            let meals = (0..<mealCount).map { index in
                MealBuilder().withMealType(.lunch).withItems(["Meal \(index)"]).withScore(0.7).build()
            }
            return DailySmileySnapshotBuilder().daysAgo(daysAgo).withMeals(meals).build()
        }

        // MARK: - Tests: Selected Date State

        func test_selectedDate_defaultsToToday() {
            let today = Calendar.current.startOfDay(for: Date())
            let selectedDay = Calendar.current.startOfDay(for: self.sut.selectedDate)

            XCTAssertEqual(selectedDay, today)
        }

        func test_isViewingToday_returnsTrueByDefault() {
            XCTAssertTrue(self.sut.isViewingToday)
        }

        func test_isViewingToday_returnsFalseWhenViewingPastDay() {
            // Arrange
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

            // Act
            self.sut.navigateToDate(yesterday)

            // Then
            XCTAssertFalse(self.sut.isViewingToday)
        }

        // MARK: - Tests: Navigation Methods

        func test_navigateToDate_updatesSelectedDate() {
            // Arrange
            let targetDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!

            // Act
            self.sut.navigateToDate(targetDate)

            // Then
            let selectedDay = Calendar.current.startOfDay(for: self.sut.selectedDate)
            let targetDay = Calendar.current.startOfDay(for: targetDate)
            XCTAssertEqual(selectedDay, targetDay)
        }

        func test_navigateToDate_cannotNavigateToFuture() {
            // Arrange
            let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
            let todayStart = Calendar.current.startOfDay(for: Date())

            // Act
            self.sut.navigateToDate(futureDate)

            // Then - Should clamp to today
            let selectedDay = Calendar.current.startOfDay(for: self.sut.selectedDate)
            XCTAssertEqual(selectedDay, todayStart, "Should not navigate to future dates")
        }

        func test_navigateToPreviousDay_movesBackOneDay() {
            // Arrange
            let today = Calendar.current.startOfDay(for: Date())
            let expectedYesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

            // Act
            self.sut.navigateToPreviousDay()

            // Then
            let selectedDay = Calendar.current.startOfDay(for: self.sut.selectedDate)
            XCTAssertEqual(selectedDay, expectedYesterday)
        }

        func test_navigateToNextDay_movesForwardOneDay() {
            // Arrange - Start from 2 days ago
            let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            self.sut.navigateToDate(twoDaysAgo)
            let expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

            // Act
            self.sut.navigateToNextDay()

            // Then
            let selectedDay = Calendar.current.startOfDay(for: self.sut.selectedDate)
            let expected = Calendar.current.startOfDay(for: expectedDate)
            XCTAssertEqual(selectedDay, expected)
        }

        func test_navigateToNextDay_doesNotExceedToday() {
            // Arrange - Already on today
            let today = Calendar.current.startOfDay(for: Date())

            // Act
            self.sut.navigateToNextDay()

            // Then - Should stay on today
            let selectedDay = Calendar.current.startOfDay(for: self.sut.selectedDate)
            XCTAssertEqual(selectedDay, today)
        }

        func test_navigateToToday_returnsToCurrentDay() {
            // Arrange - Navigate to past
            let pastDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
            self.sut.navigateToDate(pastDate)
            XCTAssertFalse(self.sut.isViewingToday)

            // Act
            self.sut.navigateToToday()

            // Then
            XCTAssertTrue(self.sut.isViewingToday)
        }

        // MARK: - Tests: Meals for Selected Date

        func test_mealsForSelectedDate_returnsTodaysMeals_whenViewingToday() {
            // Arrange
            self.sut.createNewMeal()
            self.sut.createNewMeal()

            // Act
            let meals = self.sut.mealsForSelectedDate()

            // Then
            XCTAssertEqual(meals.count, 2)
        }

        func test_mealsForSelectedDate_returnsHistoricalMeals_whenViewingPastDay() {
            // Arrange - Add historical snapshot
            let snapshot = self.createHistoricalSnapshot(daysAgo: 3, mealCount: 4)
            self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)

            // Navigate to that day
            let pastDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
            self.sut.navigateToDate(pastDate)

            // Act
            let meals = self.sut.mealsForSelectedDate()

            // Then
            XCTAssertEqual(meals.count, 4)
        }

        func test_mealsForSelectedDate_returnsEmptyArray_whenNoHistoricalData() {
            // Arrange - Navigate to a day with no data
            let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            self.sut.navigateToDate(pastDate)

            // Act
            let meals = self.sut.mealsForSelectedDate()

            // Then
            XCTAssertTrue(meals.isEmpty)
        }

        // MARK: - Tests: Snapshot for Selected Date

        func test_snapshotForSelectedDate_returnsNil_forTodayWithoutArchive() {
            // Today's data is not yet archived
            let snapshot = self.sut.snapshotForSelectedDate()

            XCTAssertNil(snapshot, "Today should not have a snapshot until archived")
        }

        func test_snapshotForSelectedDate_returnsSnapshot_forHistoricalDay() {
            // Arrange
            let snapshot = self.createHistoricalSnapshot(daysAgo: 2)
            self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)

            let pastDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            self.sut.navigateToDate(pastDate)

            // Act
            let result = self.sut.snapshotForSelectedDate()

            // Then
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.mealCount, 2)
        }

        // MARK: - Tests: Formatted Date

        func test_formattedSelectedDate_returnsCorrectFormat() {
            // The format should be like "Monday, 5 Jan 2026"
            let formatted = self.sut.formattedSelectedDate

            // Should contain day name and date
            XCTAssertFalse(formatted.isEmpty)
            XCTAssertTrue(formatted.contains(","), "Should contain comma separator")
        }

        // MARK: - Tests: Navigation Bounds

        func test_canNavigateToPreviousDay_returnsTrue_whenWithinBounds() {
            // Default is today, so we can go back
            XCTAssertTrue(self.sut.canNavigateToPreviousDay)
        }

        func test_canNavigateToNextDay_returnsFalse_whenOnToday() {
            XCTAssertFalse(self.sut.canNavigateToNextDay)
        }

        func test_canNavigateToNextDay_returnsTrue_whenViewingPastDay() {
            // Arrange
            let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
            self.sut.navigateToDate(pastDate)

            // Then
            XCTAssertTrue(self.sut.canNavigateToNextDay)
        }

        // MARK: - Tests: Day Index for Paging

        func test_selectedDayIndex_returnsZero_forToday() {
            XCTAssertEqual(self.sut.selectedDayIndex, 0)
        }

        func test_selectedDayIndex_returnsCorrectValue_forPastDays() {
            // Arrange - Navigate to 5 days ago
            let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
            self.sut.navigateToDate(pastDate)

            // Then
            XCTAssertEqual(self.sut.selectedDayIndex, 5)
        }

        func test_navigateToIndex_updatesSelectedDate() {
            // Act - Navigate to index 3 (3 days ago)
            self.sut.navigateToIndex(3)

            // Then
            XCTAssertEqual(self.sut.selectedDayIndex, 3)
            XCTAssertFalse(self.sut.isViewingToday)
        }

        func test_navigateToIndex_clampsToValidRange() {
            // Act - Try to navigate to negative index
            self.sut.navigateToIndex(-5)

            // Then - Should be clamped to 0 (today)
            XCTAssertEqual(self.sut.selectedDayIndex, 0)
        }

        // MARK: - Tests: Max Days Back

        func test_maxDaysBack_defaultsTo30() {
            XCTAssertEqual(MainViewModel.maxDaysBack, 30)
        }

        func test_navigateToIndex_respectsMaxDaysBack() {
            // Act - Try to navigate beyond max
            self.sut.navigateToIndex(100)

            // Then - Should be clamped to maxDaysBack
            XCTAssertEqual(self.sut.selectedDayIndex, MainViewModel.maxDaysBack)
        }
    }
#endif
