#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    // MARK: - Phase 3: caloriePillData computed property on MainViewModel

    @MainActor
    final class CaloriePillViewModelTests: XCTestCase {
        // MARK: - Helpers

        private func makeProfile(tdee: Double) -> UserHealthProfile {
            UserHealthProfile(
                age: 30,
                bmi: 22.0,
                bmiCategory: .normal,
                bmr: tdee / 1.55,
                tdee: tdee,
                riskLevel: .low,
                sensitivityMultiplier: 1.0
            )
        }

        private func makeMeal(calories: Int?) -> Meal {
            var meal = Meal(mealType: .lunch, items: ["Test food"])
            meal.estimatedCalories = calories
            return meal
        }

        private func makeViewModel(
            profile: UserHealthProfile? = nil,
            meals: [Meal] = []
        ) -> MainViewModel {
            let mockProfile = MockHealthProfileService()
            mockProfile.mockProfile = profile
            let vm = MainViewModel(
                healthProfileService: mockProfile,
                skipDataLoading: true
            )
            vm.meals = meals
            return vm
        }

        // MARK: - caloriePillData — no profile

        func test_caloriePillData_noProfile_noMeals_returnsNilData() {
            let vm = self.makeViewModel(profile: nil, meals: [])
            // nil tdee, zero consumed → isVisible = false → pill hides itself
            let data = vm.caloriePillData
            XCTAssertFalse(data.isVisible, "Pill should be invisible with no profile and no meals")
        }

        func test_caloriePillData_noProfile_withMeals_showsConsumedOnlyNilTDEE() {
            let meals = [makeMeal(calories: 500), makeMeal(calories: 300)]
            let vm = self.makeViewModel(profile: nil, meals: meals)
            let data = vm.caloriePillData
            XCTAssertEqual(data.consumed, 800)
            XCTAssertNil(data.tdee, "No profile means no TDEE")
            XCTAssertTrue(data.isVisible, "Pill should show when calories exist even without profile")
        }

        // MARK: - caloriePillData — with profile

        func test_caloriePillData_withProfile_noMeals_showsZeroConsumedWithTDEE() {
            let vm = self.makeViewModel(profile: self.makeProfile(tdee: 2000), meals: [])
            let data = vm.caloriePillData
            XCTAssertEqual(data.consumed, 0)
            XCTAssertEqual(data.tdee, 2000)
            XCTAssertTrue(data.isVisible, "Pill visible when TDEE exists even with zero consumed")
        }

        func test_caloriePillData_withProfile_withMeals_sumsMealCalories() {
            let meals = [makeMeal(calories: 600), makeMeal(calories: 450), makeMeal(calories: 300)]
            let vm = self.makeViewModel(profile: self.makeProfile(tdee: 2250), meals: meals)
            let data = vm.caloriePillData
            XCTAssertEqual(data.consumed, 1350)
            XCTAssertEqual(data.tdee, 2250)
        }

        func test_caloriePillData_withProfile_ignoresNilCalorieMeals() {
            let meals = [makeMeal(calories: 500), makeMeal(calories: nil), makeMeal(calories: 200)]
            let vm = self.makeViewModel(profile: self.makeProfile(tdee: 2000), meals: meals)
            let data = vm.caloriePillData
            XCTAssertEqual(data.consumed, 700, "Nil-calorie meals contribute 0")
        }

        // MARK: - caloriePillData — TDEE rounding

        func test_caloriePillData_tdeeRoundedToInt() {
            let vm = self.makeViewModel(profile: self.makeProfile(tdee: 2187.7), meals: [])
            let data = vm.caloriePillData
            XCTAssertEqual(data.tdee, 2188, "TDEE should be rounded to nearest Int")
        }

        // MARK: - R1: caloriePillData non-optional compile contract

        /// Compile-time guard: caloriePillData must be CaloriePillData, not CaloriePillData?
        func test_caloriePillData_isNonOptional() {
            let vm = self.makeViewModel()
            let data: CaloriePillData = vm.caloriePillData
            XCTAssertNotNil(data) // always true; this is a compile-time contract test
        }

        // MARK: - R1: historicalCaloriePillData

        private func makeViewModelWithHistory(
            profile: UserHealthProfile? = nil,
            snapshotsToAdd: [(date: Date, totalCalories: Int?)] = []
        ) -> MainViewModel {
            let mockProfile = MockHealthProfileService()
            mockProfile.mockProfile = profile
            let mockHistorical = MockHistoricalDataService()
            for (date, calories) in snapshotsToAdd {
                let snapshot = DailySmileySnapshot(
                    id: UUID(),
                    date: date,
                    smileyState: .neutral,
                    meals: [],
                    mealCount: 0,
                    averageHealthScore: 0.5,
                    totalCalories: calories
                )
                mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)
            }
            return MainViewModel(
                healthProfileService: mockProfile,
                historicalService: mockHistorical,
                skipDataLoading: true
            )
        }

        func test_historicalCaloriePillData_noSnapshot_returnsNil() {
            let vm = self.makeViewModelWithHistory(profile: nil, snapshotsToAdd: [])
            XCTAssertNil(vm.historicalCaloriePillData(for: Date()))
        }

        func test_historicalCaloriePillData_snapshotWithNoCalories_returnsNil() {
            let date = Date()
            let vm = self.makeViewModelWithHistory(snapshotsToAdd: [(date: date, totalCalories: nil)])
            XCTAssertNil(vm.historicalCaloriePillData(for: date))
        }

        func test_historicalCaloriePillData_snapshotWithCalories_returnsData() {
            let date = Date()
            let profile = self.makeProfile(tdee: 2000)
            let vm = self.makeViewModelWithHistory(
                profile: profile,
                snapshotsToAdd: [(date: date, totalCalories: 1400)]
            )
            let result = vm.historicalCaloriePillData(for: date)
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.consumed, 1400)
            XCTAssertEqual(result?.tdee, 2000)
        }

        func test_historicalCaloriePillData_noProfile_snapshotWithCalories_tdeeIsNil() {
            let date = Date()
            let vm = self.makeViewModelWithHistory(
                profile: nil,
                snapshotsToAdd: [(date: date, totalCalories: 800)]
            )
            let result = vm.historicalCaloriePillData(for: date)
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.consumed, 800)
            XCTAssertNil(result?.tdee, "No profile means no TDEE for historical pill")
        }

        // MARK: - R4: ActivityDataProvider + TDEE resolution chain

        private func makeViewModelWithActivity(
            profile: UserHealthProfile? = nil,
            meals: [Meal] = [],
            basalCalories: Double? = nil,
            activeCalories: Double? = nil
        ) -> MainViewModel {
            let mockProfile = MockHealthProfileService()
            mockProfile.mockProfile = profile
            let mockActivity = MockActivityDataProvider()
            mockActivity.stubbedActiveCalories = activeCalories
            mockActivity.stubbedBasalCalories = basalCalories
            let vm = MainViewModel(
                healthProfileService: mockProfile,
                activityProvider: mockActivity,
                skipDataLoading: true
            )
            vm.meals = meals
            return vm
        }

        func test_caloriePillData_tdeeFromHealthKit_basalPlusActive() async {
            let profile = self.makeProfile(tdee: 2000)
            let vm = self.makeViewModelWithActivity(profile: profile, basalCalories: 1400, activeCalories: 400)
            await vm.loadTodayActivityData()
            // basal + active = 1800 overrides static TDEE
            XCTAssertEqual(vm.caloriePillData.tdee, 1800)
        }

        func test_caloriePillData_tdeeHybrid_profileBMRPlusActiveWhenBasalMissing() async {
            // BMR = 2000 / 1.55 ≈ 1290; active = 350 → tdee ≈ 1640
            let profile = self.makeProfile(tdee: 2000)
            let vm = self.makeViewModelWithActivity(profile: profile, basalCalories: nil, activeCalories: 350)
            await vm.loadTodayActivityData()
            let expectedBMR = Int((2000.0 / 1.55).rounded())
            let expectedTDEE = expectedBMR + 350
            XCTAssertEqual(vm.caloriePillData.tdee, expectedTDEE)
        }

        func test_caloriePillData_tdeeFallback_profileStaticTDEEWhenNoHealthKit() async {
            let profile = self.makeProfile(tdee: 2100)
            let vm = self.makeViewModelWithActivity(profile: profile, basalCalories: nil, activeCalories: nil)
            await vm.loadTodayActivityData()
            // No HealthKit data → falls back to static profile TDEE
            XCTAssertEqual(vm.caloriePillData.tdee, 2100)
        }

        func test_caloriePillData_tdeeNil_whenNoProfileAndNoHealthKit() async {
            let vm = self.makeViewModelWithActivity(profile: nil, basalCalories: nil, activeCalories: nil)
            await vm.loadTodayActivityData()
            XCTAssertNil(vm.caloriePillData.tdee)
        }

        func test_mainViewModel_loadTodayActivityData_updatesPublishedProperties() async {
            let vm = self.makeViewModelWithActivity(basalCalories: 1500, activeCalories: 300)
            await vm.loadTodayActivityData()
            XCTAssertEqual(vm.todayActiveCalories, 300)
            XCTAssertEqual(vm.todayBasalCalories, 1500)
        }

        // MARK: - R5: calorieDetailData computed property

        func test_calorieDetailData_perMealBreakdown_matchesMeals() async {
            var breakfast = Meal(mealType: .breakfast, items: ["Oats"])
            breakfast.estimatedCalories = 350
            var lunch = Meal(mealType: .lunch, items: ["Salad"])
            lunch.estimatedCalories = 500
            let vm = self.makeViewModelWithActivity(meals: [breakfast, lunch])
            await vm.loadTodayActivityData()
            XCTAssertEqual(vm.calorieDetailData.mealBreakdown.count, 2)
        }

        func test_calorieDetailData_remainingCalories_nilWhenNoProfile() async {
            let vm = self.makeViewModelWithActivity(profile: nil)
            await vm.loadTodayActivityData()
            XCTAssertNil(vm.calorieDetailData.remaining)
        }

        func test_integration_snapshotPreservesTotalCalories() {
            var meal = Meal(mealType: .lunch, items: ["Rice"])
            meal.estimatedCalories = 600
            let vm = MainViewModel(
                skipDataLoading: true
            )
            vm.meals = [meal]
            // After archive, snapshot should carry totalCalories = 600
            vm.historicalService.archiveCurrentDay(
                meals: [meal],
                state: .neutral,
                date: Date()
            )
            let snapshot = vm.historicalService.getSnapshot(for: Date())
            XCTAssertEqual(snapshot?.totalCalories, 600)
        }

        func test_integration_mealAnalyzed_pillDataUpdates() {
            var meal = Meal(mealType: .lunch, items: ["Pasta"])
            meal.estimatedCalories = nil
            let vm = self.makeViewModel(meals: [meal])
            XCTAssertEqual(vm.caloriePillData.consumed, 0, "No analyzed meals → 0 consumed")

            meal.estimatedCalories = 800
            vm.meals = [meal]
            XCTAssertEqual(vm.caloriePillData.consumed, 800)
        }

        // MARK: - Activity Refresh (Phase 2 — RED)

        func test_refreshActivityDataIfNeeded_populatesActivityData_onFirstCall() async {
            let mockActivity = MockActivityDataProvider()
            mockActivity.stubbedActiveCalories = 300
            mockActivity.stubbedBasalCalories = 1500
            let vm = MainViewModel(activityProvider: mockActivity, skipDataLoading: true)
            vm.refreshActivityDataIfNeeded()
            try? await Task.sleep(nanoseconds: 200_000_000)
            XCTAssertEqual(vm.todayActiveCalories, 300, "First call should populate active calories")
            XCTAssertEqual(vm.todayBasalCalories, 1500, "First call should populate basal calories")
        }

        func test_refreshActivityDataIfNeeded_cooldown_doesNotRefetchWithinWindow() async {
            let mockActivity = MockActivityDataProvider()
            mockActivity.stubbedActiveCalories = 300
            let vm = MainViewModel(activityProvider: mockActivity, skipDataLoading: true)
            vm.refreshActivityDataIfNeeded()
            try? await Task.sleep(nanoseconds: 200_000_000)
            vm.refreshActivityDataIfNeeded()
            try? await Task.sleep(nanoseconds: 100_000_000)
            XCTAssertEqual(mockActivity.fetchCallCount, 1, "Second call within cooldown window should be a no-op")
        }

        func test_loadData_callsActivityDataRefresh() async {
            let mockActivity = MockActivityDataProvider()
            mockActivity.stubbedActiveCalories = 450
            let vm = MainViewModel(activityProvider: mockActivity, skipDataLoading: false)
            try? await Task.sleep(nanoseconds: 300_000_000)
            XCTAssertNotNil(vm.lastActivityDataFetchDate, "loadData should trigger activity refresh")
        }
    }

#endif
