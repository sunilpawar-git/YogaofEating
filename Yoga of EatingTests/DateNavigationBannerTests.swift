#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Unit tests for DateNavigationBanner data and MainViewModel date navigation state.
    /// Tests cover what the banner receives from the ViewModel — formatted date strings,
    /// navigation enable/disable flags, and boundary behaviour.
    @MainActor
    final class DateNavigationBannerTests: XCTestCase {
        // MARK: - Properties

        var sut: MainViewModel!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.sut = MainViewModel(
                logicService: MockMealLogicService(),
                persistenceService: MockPersistenceService(),
                historicalService: MockHistoricalDataService(),
                skipDataLoading: true
            )
        }

        override func tearDown() {
            self.sut = nil
            super.tearDown()
        }

        // MARK: - Today state

        func test_isViewingToday_trueOnInit() {
            XCTAssertTrue(self.sut.isViewingToday)
        }

        func test_canNavigateToPreviousDay_trueOnInit() {
            XCTAssertTrue(self.sut.canNavigateToPreviousDay)
        }

        func test_canNavigateToNextDay_falseWhenViewingToday() {
            XCTAssertFalse(self.sut.canNavigateToNextDay)
        }

        // MARK: - Navigating back

        func test_navigateToPreviousDay_isNoLongerViewingToday() {
            self.sut.navigateToPreviousDay()
            XCTAssertFalse(self.sut.isViewingToday)
        }

        func test_navigateToPreviousDay_canNavigateToNextDay() {
            self.sut.navigateToPreviousDay()
            XCTAssertTrue(self.sut.canNavigateToNextDay)
        }

        func test_navigateToPreviousDay_selectedDateIsYesterday() {
            let expected = Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: Calendar.current.startOfDay(for: Date())
            )!
            self.sut.navigateToPreviousDay()
            XCTAssertEqual(Calendar.current.startOfDay(for: self.sut.selectedDate), expected)
        }

        // MARK: - Navigate back to today

        func test_navigateToToday_resetsViewingToday() {
            self.sut.navigateToPreviousDay()
            self.sut.navigateToToday()
            XCTAssertTrue(self.sut.isViewingToday)
        }

        func test_navigateToToday_disablesNextDayArrow() {
            self.sut.navigateToPreviousDay()
            self.sut.navigateToToday()
            XCTAssertFalse(self.sut.canNavigateToNextDay)
        }

        // MARK: - Max navigation limit

        func test_canNavigateToPreviousDay_falseWhenAtMaxDaysBack() {
            for _ in 0..<MainViewModel.maxDaysBack {
                self.sut.navigateToPreviousDay()
            }
            XCTAssertFalse(self.sut.canNavigateToPreviousDay)
        }

        // MARK: - Formatted date string

        func test_formattedSelectedDate_isNonEmpty() {
            XCTAssertFalse(self.sut.formattedSelectedDate.isEmpty)
        }

        func test_formattedSelectedDate_changesOnNavigation() {
            let today = self.sut.formattedSelectedDate
            self.sut.navigateToPreviousDay()
            XCTAssertNotEqual(self.sut.formattedSelectedDate, today)
        }
    }
#endif
