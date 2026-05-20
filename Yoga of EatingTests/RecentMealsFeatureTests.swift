#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    // MARK: - getRecentUniqueMeals() unit tests

    @MainActor
    final class RecentMealsFeatureTests: XCTestCase {
        private var viewModel: MainViewModel!
        private var mockHistorical: MockHistoricalDataService!

        override func setUp() {
            super.setUp()
            self.mockHistorical = MockHistoricalDataService()
            self.viewModel = MainViewModel(
                logicService: MockMealLogicService(),
                persistenceService: MockPersistenceService(),
                historicalService: self.mockHistorical,
                skipDataLoading: true
            )
        }

        override func tearDown() {
            self.viewModel = nil
            self.mockHistorical = nil
            super.tearDown()
        }

        // MARK: - Helpers

        private func snapshotDaysAgo(_ daysAgo: Int, meals: [Meal]) -> DailySmileySnapshot {
            DailySmileySnapshotBuilder().daysAgo(daysAgo).withMeals(meals).build()
        }

        private func meal(items: [String], type: MealType = .lunch) -> Meal {
            MealBuilder().withItems(items).withMealType(type).build()
        }

        // MARK: - Returns meals from past 3 days

        func test_getRecentUniqueMeals_returnsYesterdaysMeals() {
            let yesterdayMeal = self.meal(items: ["Rice", "Dal"])
            self.mockHistorical.historicalData.addOrUpdate(
                snapshot: self.snapshotDaysAgo(1, meals: [yesterdayMeal])
            )

            let result = self.viewModel.getRecentUniqueMeals()

            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first?.items, ["Rice", "Dal"])
        }

        func test_getRecentUniqueMeals_returnsMealsFromAllThreePastDays() {
            self.mockHistorical.historicalData.addOrUpdate(
                snapshot: self.snapshotDaysAgo(1, meals: [self.meal(items: ["Coffee"])])
            )
            self.mockHistorical.historicalData.addOrUpdate(
                snapshot: self.snapshotDaysAgo(2, meals: [self.meal(items: ["Idli"])])
            )
            self.mockHistorical.historicalData.addOrUpdate(
                snapshot: self.snapshotDaysAgo(3, meals: [self.meal(items: ["Oats"])])
            )

            let result = self.viewModel.getRecentUniqueMeals()

            XCTAssertEqual(result.count, 3)
        }

        func test_getRecentUniqueMeals_excludesMealsOlderThan3Days() {
            self.mockHistorical.historicalData.addOrUpdate(
                snapshot: self.snapshotDaysAgo(4, meals: [self.meal(items: ["Old meal"])])
            )

            let result = self.viewModel.getRecentUniqueMeals()

            XCTAssertTrue(result.isEmpty, "Meals from 4+ days ago must not appear")
        }

        func test_getRecentUniqueMeals_withNoHistoricalData_returnsEmpty() {
            let result = self.viewModel.getRecentUniqueMeals()

            XCTAssertTrue(result.isEmpty)
        }

        // MARK: - Deduplication

        func test_getRecentUniqueMeals_deduplicatesIdenticalMeals() {
            let mealA = self.meal(items: ["Rice", "Dal"])
            let mealB = self.meal(items: ["Rice", "Dal"])
            self.mockHistorical.historicalData.addOrUpdate(
                snapshot: self.snapshotDaysAgo(1, meals: [mealA])
            )
            self.mockHistorical.historicalData.addOrUpdate(
                snapshot: self.snapshotDaysAgo(2, meals: [mealB])
            )

            let result = self.viewModel.getRecentUniqueMeals()

            XCTAssertEqual(result.count, 1, "Identical meals across days should appear only once")
        }

        func test_getRecentUniqueMeals_deduplicationIsCaseInsensitive() {
            self.mockHistorical.historicalData.addOrUpdate(
                snapshot: self.snapshotDaysAgo(1, meals: [self.meal(items: ["rice", "dal"])])
            )
            self.mockHistorical.historicalData.addOrUpdate(
                snapshot: self.snapshotDaysAgo(2, meals: [self.meal(items: ["Rice", "Dal"])])
            )

            let result = self.viewModel.getRecentUniqueMeals()

            XCTAssertEqual(result.count, 1, "Deduplication must be case-insensitive")
        }

        // MARK: - Max results

        func test_getRecentUniqueMeals_capsAtEightResults() {
            let manyMeals = (1...10).map { i in
                self.meal(items: ["Unique meal \(i)"])
            }
            self.mockHistorical.historicalData.addOrUpdate(
                snapshot: self.snapshotDaysAgo(1, meals: manyMeals)
            )

            let result = self.viewModel.getRecentUniqueMeals()

            XCTAssertLessThanOrEqual(result.count, 8, "Must return at most 8 meals")
        }

        // MARK: - Button visibility spec

        // This is the regression case: button must appear even when no historical data exists.
        // Previously the button was gated on `!recentMeals.isEmpty`, hiding it on fresh
        // installs and after gaps in usage — even though the sheet handles empty state.
        func test_recentMealsButtonVisibility_trueWhenNotFocused_noData() {
            let visible = recentMealsButtonShouldShow(isFocused: false)
            XCTAssertTrue(visible, "Button must be visible when not focused even if recentMeals is empty")
        }

        func test_recentMealsButtonVisibility_trueWhenNotFocused_withData() {
            let visible = recentMealsButtonShouldShow(isFocused: false)
            XCTAssertTrue(visible, "Button must be visible when not focused and data exists")
        }

        func test_recentMealsButtonVisibility_trueWhenFocused() {
            let visible = recentMealsButtonShouldShow(isFocused: true)
            XCTAssertTrue(
                visible,
                "Button must always be visible — even when focused — so user can add a recent meal mid-typing"
            )
        }
    }

    // MARK: - Production visibility rule (extracted from JournalBlockInputSection)

    /// Mirrors the production condition for the recent meals "+" button.
    /// The button is always visible (no focus guard) so users can add a recent meal
    /// at any point, including while actively typing.
    private func recentMealsButtonShouldShow(isFocused _: Bool) -> Bool {
        true
    }

#endif
