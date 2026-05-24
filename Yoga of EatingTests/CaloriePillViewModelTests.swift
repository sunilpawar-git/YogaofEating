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
                sensitivityMultiplier: 1.0,
                activityLevel: .sedentary
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

        // MARK: - MFP TDEE resolution (profile.tdee + actual active)

        func test_resolvedTDEE_mfpApproach_profileTDEEPlusActive_basalIgnored() async {
            // MFP model: base = profile.tdee (stable), not basal from HealthKit.
            // Even when basal is available, it is NOT used as the base — profile.tdee is.
            let profile = self.makeProfile(tdee: 2000)
            let vm = self.makeViewModelWithActivity(profile: profile, basalCalories: 1400, activeCalories: 400)
            await vm.loadTodayActivityData()
            // Expected: profile.tdee (2000) + active (400) = 2400, NOT basal+active (1800)
            XCTAssertEqual(vm.caloriePillData.tdee, 2400)
        }

        func test_resolvedTDEE_mfpApproach_profileTDEEPlusActive_whenBasalMissing() async {
            // Basal missing but profile exists — still uses profile.tdee as base.
            let profile = self.makeProfile(tdee: 2000)
            let vm = self.makeViewModelWithActivity(profile: profile, basalCalories: nil, activeCalories: 350)
            await vm.loadTodayActivityData()
            // Expected: profile.tdee (2000) + active (350) = 2350, NOT profileBMR + active
            XCTAssertEqual(vm.caloriePillData.tdee, 2350)
        }

        func test_resolvedTDEE_nilActiveCalories_treatedAsZero_returnsProfileTDEE() async {
            // When HealthKit active data is unavailable (nil), it defaults to 0.
            // TDEE = profile.tdee + 0 = profile.tdee exactly.
            let profile = self.makeProfile(tdee: 2100)
            let vm = self.makeViewModelWithActivity(profile: profile, basalCalories: nil, activeCalories: nil)
            await vm.loadTodayActivityData()
            XCTAssertEqual(vm.caloriePillData.tdee, 2100)
        }

        func test_resolvedTDEE_noProfileWithHealthKit_projectsBasalToNonNil() async {
            // No profile but HealthKit has basal data — Tier 2 projects basal to full-day.
            // Exact value is time-of-day dependent; we assert structural guarantees only.
            let vm = self.makeViewModelWithActivity(profile: nil, basalCalories: 800, activeCalories: 200)
            await vm.loadTodayActivityData()
            let tdee = vm.caloriePillData.tdee
            XCTAssertNotNil(tdee, "With HealthKit basal data, TDEE must be projected (not nil)")
            XCTAssertGreaterThanOrEqual(tdee ?? 0, 800 + 200, "Projected full-day TDEE must be >= actual burned so far")
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

        // MARK: - MFP: calorieDetailData.profileBaseTdee (breakdown regression)

        func test_calorieDetailData_profileBaseTdee_populatedWhenProfileExists() async {
            // When a profile exists, detail sheet must receive the base TDEE for breakdown display.
            let profile = self.makeProfile(tdee: 1909)
            let vm = self.makeViewModelWithActivity(profile: profile, basalCalories: 738, activeCalories: 151)
            await vm.loadTodayActivityData()
            XCTAssertEqual(vm.calorieDetailData.profileBaseTdee, 1909)
        }

        func test_calorieDetailData_profileBaseTdee_nilWhenNoProfile() async {
            // No profile → no breakdown possible → profileBaseTdee must be nil.
            let vm = self.makeViewModelWithActivity(profile: nil, basalCalories: 800, activeCalories: 100)
            await vm.loadTodayActivityData()
            XCTAssertNil(vm.calorieDetailData.profileBaseTdee)
        }

        func test_calorieDetailData_tdeeEqualsProflieTDEEPlusActive() async {
            // Verifies the MFP arithmetic: detail.tdee must equal base + exercise, not basal + active.
            let profile = self.makeProfile(tdee: 1909)
            let vm = self.makeViewModelWithActivity(profile: profile, basalCalories: 738, activeCalories: 151)
            await vm.loadTodayActivityData()
            let detail = vm.calorieDetailData
            XCTAssertEqual(detail.tdee, 2060, "TDEE must be 1909 + 151 = 2060, not 738 + 151 = 889")
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

        // MARK: - Activity Refresh

        /// Verifies that `refreshActivityDataIfNeeded()` sets `lastActivityDataFetchDate`
        /// on first call (synchronous guard side-effect) — does not require Task timing.
        func test_refreshActivityDataIfNeeded_setsLastFetchDate_onFirstCall() {
            let mockActivity = MockActivityDataProvider()
            let vm = MainViewModel(activityProvider: mockActivity, skipDataLoading: true)
            XCTAssertNil(vm.lastActivityDataFetchDate, "Pre-condition: no prior fetch")
            vm.refreshActivityDataIfNeeded()
            XCTAssertNotNil(vm.lastActivityDataFetchDate, "First call must set lastActivityDataFetchDate")
        }

        /// Verifies that a second `refreshActivityDataIfNeeded()` call within the cooldown
        /// window does not trigger another data fetch.
        func test_refreshActivityDataIfNeeded_cooldown_doesNotRefetchWithinWindow() async {
            let mockActivity = MockActivityDataProvider()
            mockActivity.stubbedActiveCalories = 300
            mockActivity.stubbedBasalCalories = 1200
            let vm = MainViewModel(activityProvider: mockActivity, skipDataLoading: true)
            // Use direct await to deterministically complete the first fetch
            await vm.loadTodayActivityData()
            let firstCallCount = mockActivity.fetchCallCount
            // Immediately call refresh — cooldown should block it
            vm.refreshActivityDataIfNeeded()
            // lastActivityDataFetchDate not set yet (no prior refreshActivityDataIfNeeded call),
            // so call it once to prime the date, then verify a second call is blocked
            vm.refreshActivityDataIfNeeded() // primes lastActivityDataFetchDate
            let countAfterPriming = mockActivity.fetchCallCount
            vm.refreshActivityDataIfNeeded() // should be blocked by cooldown
            XCTAssertEqual(
                mockActivity.fetchCallCount,
                countAfterPriming,
                "Call within cooldown window must not trigger additional fetches"
            )
            _ = firstCallCount // suppress unused warning
        }

        /// Verifies that `loadData()` calls `refreshActivityDataIfNeeded()` by checking
        /// `lastActivityDataFetchDate` is set (synchronous, no timing dependency).
        func test_loadData_callsActivityDataRefresh() {
            let mockActivity = MockActivityDataProvider()
            mockActivity.stubbedActiveCalories = 450
            let vm = MainViewModel(activityProvider: mockActivity, skipDataLoading: true)
            XCTAssertNil(vm.lastActivityDataFetchDate, "Pre-condition: no prior fetch")
            vm.loadData()
            XCTAssertNotNil(
                vm.lastActivityDataFetchDate,
                "loadData() must trigger refreshActivityDataIfNeeded(), setting lastActivityDataFetchDate"
            )
        }
    }

#endif
