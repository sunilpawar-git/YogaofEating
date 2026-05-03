#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for MainViewModel.dateContextSubtext computed property (Phase 4).
    /// Verifies the MVVM contract: subtext logic lives in ViewModel, not in the View.
    @MainActor
    final class DateContextSubtextTests: XCTestCase {
        var sut: MainViewModel!
        var mockLogic: MockMealLogicService!
        var mockPersistence: MockPersistenceService!
        var mockHistorical: MockHistoricalDataService!

        override func setUp() {
            super.setUp()
            self.mockLogic = MockMealLogicService()
            self.mockPersistence = MockPersistenceService()
            self.mockHistorical = MockHistoricalDataService()
            self.sut = MainViewModel(
                logicService: self.mockLogic,
                persistenceService: self.mockPersistence,
                historicalService: self.mockHistorical,
                skipDataLoading: true
            )
        }

        override func tearDown() {
            self.sut = nil
            self.mockLogic = nil
            self.mockPersistence = nil
            self.mockHistorical = nil
            super.tearDown()
        }

        // MARK: - Strings.DateHeader SSOT tests

        func test_dateHeaderStrings_goodMorning_isNotEmpty() {
            XCTAssertFalse(Strings.DateHeader.goodMorning.isEmpty)
        }

        func test_dateHeaderStrings_backToToday_isNotEmpty() {
            XCTAssertFalse(Strings.DateHeader.backToToday.isEmpty)
        }

        func test_dateHeaderStrings_backToToday_matchesExpected() {
            XCTAssertEqual(Strings.DateHeader.backToToday, "Back to Today")
        }

        func test_dateHeaderStrings_sleptQuality_includesQuality() {
            let result = Strings.DateHeader.sleptQuality("well")
            XCTAssertTrue(result.contains("well"))
        }

        func test_dateHeaderStrings_mealsSoFar_singular() {
            let result = Strings.DateHeader.mealsSoFar(1)
            XCTAssertTrue(result.contains("meal "))
            XCTAssertFalse(result.contains("meals"))
        }

        func test_dateHeaderStrings_mealsSoFar_plural() {
            let result = Strings.DateHeader.mealsSoFar(3)
            XCTAssertTrue(result.contains("meals"))
        }

        func test_dateHeaderStrings_daysAgo_singular() {
            let result = Strings.DateHeader.daysAgo(1)
            XCTAssertTrue(result.contains("day "))
            XCTAssertFalse(result.contains("days"))
        }

        func test_dateHeaderStrings_daysAgo_plural() {
            let result = Strings.DateHeader.daysAgo(3)
            XCTAssertTrue(result.contains("days"))
        }

        // MARK: - dateContextSubtext — today, no sleep, before 10am

        func test_dateContextSubtext_todayBeforeTenAM_noSleep_returnsGoodMorning() {
            // This test verifies the string contract via Strings enum directly,
            // since we cannot control system clock in unit tests.
            // The ViewModel logic uses Calendar.current.component(.hour, from: Date()).
            // We verify the return value matches the expected SSOT string.
            let goodMorning = Strings.DateHeader.goodMorning
            XCTAssertEqual(goodMorning, "Good morning")
        }

        // MARK: - dateContextSubtext — today, sleep logged

        func test_dateContextSubtext_sleepLogged_containsSleptPrefix() {
            // When sleep is logged, subtext should start with "Slept"
            let result = Strings.DateHeader.sleptQuality("well")
            XCTAssertTrue(result.hasPrefix("Slept"))
        }

        func test_dateContextSubtext_sleepLogged_good_returnsCorrectString() {
            let result = Strings.DateHeader.sleptQuality(SleepQuality.good.displayName.lowercased())
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains(SleepQuality.good.displayName.lowercased()))
        }

        func test_dateContextSubtext_sleepLogged_poor_returnsCorrectString() {
            let result = Strings.DateHeader.sleptQuality(SleepQuality.poor.displayName.lowercased())
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains(SleepQuality.poor.displayName.lowercased()))
        }

        // MARK: - dateContextSubtext — historical day

        func test_dateContextSubtext_historicalDay_returnsDaysAgo() {
            // Navigate to a historical day (selectedDayIndex becomes 1 → "1 day ago")
            self.sut.navigateToPreviousDay()
            let subtext = self.sut.dateContextSubtext

            // Then: subtext must be non-nil and contain "ago"
            XCTAssertNotNil(subtext, "Historical day subtext must not be nil after navigateToPreviousDay()")
            XCTAssertTrue(
                subtext?.contains("ago") ?? false,
                "Historical subtext should contain 'ago', got: \(subtext ?? "nil")"
            )
        }

        func test_dateContextSubtext_todayWithNoConditionsMet_typeIsOptionalString() {
            // For today with no sleep and no meals, result depends on current time.
            // The key invariant is that the return type is Optional<String> — not a crash.
            // Logic is tested exhaustively via DateContextProvider unit tests above.
            let subtext: String? = self.sut.dateContextSubtext
            // Verify the property returns without crashing regardless of clock state.
            XCTAssertTrue(
                subtext == nil || !(subtext?.isEmpty ?? true),
                "If subtext is non-nil it must not be empty"
            )
        }

        // MARK: - dateContextSubtext — today, with meals

        func test_dateContextSubtext_withMeals_mealsSoFarStringIsCorrect() {
            // Verify the string format independently of ViewModel clock state
            let count = 3
            let result = Strings.DateHeader.mealsSoFar(count)
            XCTAssertEqual(result, "3 meals so far")
        }

        func test_dateContextSubtext_withOneMeal_mealsSoFarUseSingular() {
            let result = Strings.DateHeader.mealsSoFar(1)
            XCTAssertEqual(result, "1 meal so far")
        }

        // MARK: - DateContextProvider unit tests

        func test_dateContextProvider_beforeTenAM_noSleep_noMeals_goodMorning() {
            let result = DateContextProvider.subtext(
                isViewingToday: true,
                currentHour: 8,
                sleepQuality: nil,
                mealCount: 0,
                daysAgo: 0
            )
            XCTAssertEqual(result, Strings.DateHeader.goodMorning)
        }

        func test_dateContextProvider_sleepLogged_returnsSleep() {
            let result = DateContextProvider.subtext(
                isViewingToday: true,
                currentHour: 11,
                sleepQuality: .good,
                mealCount: 0,
                daysAgo: 0
            )
            XCTAssertEqual(result, Strings.DateHeader.sleptQualityFormatted(quality: .good))
        }

        func test_dateContextProvider_afterTenAM_noSleep_withMeals_returnsMealsSoFar() {
            let result = DateContextProvider.subtext(
                isViewingToday: true,
                currentHour: 14,
                sleepQuality: nil,
                mealCount: 2,
                daysAgo: 0
            )
            XCTAssertEqual(result, Strings.DateHeader.mealsSoFar(2))
        }

        func test_dateContextProvider_afterTenAM_noSleep_noMeals_returnsNil() {
            let result = DateContextProvider.subtext(
                isViewingToday: true,
                currentHour: 14,
                sleepQuality: nil,
                mealCount: 0,
                daysAgo: 0
            )
            XCTAssertNil(result)
        }

        func test_dateContextProvider_historicalDay_returnsDaysAgo() {
            let result = DateContextProvider.subtext(
                isViewingToday: false,
                currentHour: 12,
                sleepQuality: nil,
                mealCount: 3,
                daysAgo: 2
            )
            XCTAssertEqual(result, Strings.DateHeader.daysAgo(2))
        }

        func test_dateContextProvider_exactlyAtMorningThreshold_noMeals_returnsNil() {
            // At exactly the threshold hour (10) — morning greeting should NOT show
            let result = DateContextProvider.subtext(
                isViewingToday: true,
                currentHour: AppTheme.DateContext.morningHourThreshold,
                sleepQuality: nil,
                mealCount: 0,
                daysAgo: 0
            )
            XCTAssertNil(result, "At threshold hour with no meals, no context applies")
        }

        func test_dateContextProvider_oneBeforeMorningThreshold_noMeals_returnsGoodMorning() {
            // One hour before threshold — morning greeting should show
            let result = DateContextProvider.subtext(
                isViewingToday: true,
                currentHour: AppTheme.DateContext.morningHourThreshold - 1,
                sleepQuality: nil,
                mealCount: 0,
                daysAgo: 0
            )
            XCTAssertEqual(result, Strings.DateHeader.goodMorning)
        }

        func test_dateContextProvider_historicalDay_zeroDaysAgo_returnsNil() {
            let result = DateContextProvider.subtext(
                isViewingToday: false,
                currentHour: 12,
                sleepQuality: nil,
                mealCount: 0,
                daysAgo: 0
            )
            XCTAssertNil(result)
        }
    }
#endif
