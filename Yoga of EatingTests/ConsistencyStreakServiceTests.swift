import XCTest
@testable import Yoga_of_Eating

final class ConsistencyStreakServiceTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func makeSnapshot(
        daysAgo: Int,
        mealCount: Int,
        from today: Date = Date()
    ) -> DailySmileySnapshot {
        let date = self.calendar.date(byAdding: .day, value: -daysAgo, to: today)!
        let meals = (0..<mealCount).map { _ in
            Meal(mealType: .lunch, items: ["test"], healthScore: 0.7)
        }
        return DailySmileySnapshot(
            id: UUID(),
            date: date,
            smileyState: SmileyState(scale: 0.5, mood: .neutral),
            meals: meals,
            mealCount: mealCount,
            averageHealthScore: 0.7
        )
    }

    // MARK: - Unit Tests

    func testEmptySnapshots() {
        let result = ConsistencyStreakService.compute(from: [])

        XCTAssertEqual(result.current, 0)
        XCTAssertEqual(result.best, 0)
        XCTAssertFalse(result.todayLogged)
    }

    func testSingleDayWithMeals() {
        let today = Date()
        let snapshots = [makeSnapshot(daysAgo: 0, mealCount: 1, from: today)]

        let result = ConsistencyStreakService.compute(
            from: snapshots, today: today
        )

        XCTAssertEqual(result.current, 1)
        XCTAssertEqual(result.best, 1)
        XCTAssertTrue(result.todayLogged)
    }

    func testSingleDayNoMeals() {
        let today = Date()
        let snapshots = [makeSnapshot(daysAgo: 0, mealCount: 0, from: today)]

        let result = ConsistencyStreakService.compute(
            from: snapshots, today: today
        )

        XCTAssertEqual(result.current, 0)
        XCTAssertEqual(result.best, 0)
        XCTAssertFalse(result.todayLogged)
    }

    func testFiveConsecutiveDays() {
        let today = Date()
        let snapshots = (0..<5).map {
            self.makeSnapshot(daysAgo: $0, mealCount: 2, from: today)
        }

        let result = ConsistencyStreakService.compute(
            from: snapshots, today: today
        )

        XCTAssertEqual(result.current, 5)
        XCTAssertEqual(result.best, 5)
        XCTAssertTrue(result.todayLogged)
    }

    func testStreakBrokenTwoDaysAgo() {
        let today = Date()
        var snapshots: [DailySmileySnapshot] = []
        snapshots.append(self.makeSnapshot(daysAgo: 0, mealCount: 1, from: today))
        snapshots.append(self.makeSnapshot(daysAgo: 1, mealCount: 0, from: today))
        snapshots.append(self.makeSnapshot(daysAgo: 2, mealCount: 2, from: today))
        snapshots.append(self.makeSnapshot(daysAgo: 3, mealCount: 1, from: today))
        snapshots.append(self.makeSnapshot(daysAgo: 4, mealCount: 3, from: today))

        let result = ConsistencyStreakService.compute(
            from: snapshots, today: today
        )

        XCTAssertEqual(result.current, 1)
        XCTAssertEqual(result.best, 3)
        XCTAssertTrue(result.todayLogged)
    }

    func testTodayNoMealsYesterdayHasMeals() {
        let today = Date()
        let snapshots = [
            makeSnapshot(daysAgo: 0, mealCount: 0, from: today),
            makeSnapshot(daysAgo: 1, mealCount: 1, from: today),
            makeSnapshot(daysAgo: 2, mealCount: 2, from: today)
        ]

        let result = ConsistencyStreakService.compute(
            from: snapshots, today: today
        )

        XCTAssertEqual(result.current, 0)
        XCTAssertFalse(result.todayLogged)
        XCTAssertEqual(result.best, 2)
    }

    func testBestStreakTrackedAcrossGaps() {
        let today = Date()
        var snapshots: [DailySmileySnapshot] = []

        for day in 0...2 {
            snapshots.append(
                self.makeSnapshot(daysAgo: day, mealCount: 1, from: today)
            )
        }
        snapshots.append(
            self.makeSnapshot(daysAgo: 3, mealCount: 0, from: today)
        )
        for day in 4...8 {
            snapshots.append(
                self.makeSnapshot(daysAgo: day, mealCount: 1, from: today)
            )
        }

        let result = ConsistencyStreakService.compute(
            from: snapshots, today: today
        )

        XCTAssertEqual(result.current, 3)
        XCTAssertEqual(result.best, 5)
    }

    func testNoSnapshotForTodayButYesterdayExists() {
        let today = Date()
        let snapshots = [
            makeSnapshot(daysAgo: 1, mealCount: 2, from: today),
            makeSnapshot(daysAgo: 2, mealCount: 1, from: today)
        ]

        let result = ConsistencyStreakService.compute(
            from: snapshots, today: today
        )

        XCTAssertEqual(result.current, 0)
        XCTAssertFalse(result.todayLogged)
        XCTAssertEqual(result.best, 2)
    }

    // MARK: - todayLoggedOverride

    func testComputeWithTodayLoggedOverrideTrue_showsStreakOf1() {
        let result = ConsistencyStreakService.compute(
            from: [],
            todayLoggedOverride: true
        )

        XCTAssertEqual(result.current, 1)
        XCTAssertTrue(result.todayLogged)
    }

    func testComputeWithTodayLoggedOverrideFalse_ignoresSnapshotForToday() {
        let today = Date()
        let snapshots = [
            makeSnapshot(daysAgo: 0, mealCount: 3, from: today)
        ]

        let result = ConsistencyStreakService.compute(
            from: snapshots,
            today: today,
            todayLoggedOverride: false
        )

        XCTAssertEqual(result.current, 0)
        XCTAssertFalse(result.todayLogged)
    }

    // MARK: - Integration Test

    @MainActor
    func testMainViewModelCurrentStreakReflectsLiveMeals() {
        let viewModel = MainViewModel(
            logicService: MockMealLogicService(),
            persistenceService: MockPersistenceService(),
            historicalService: MockHistoricalDataService()
        )

        XCTAssertEqual(
            viewModel.currentStreak.current, 0,
            "No meals → streak 0"
        )

        viewModel.createNewMeal(mealType: .lunch)

        XCTAssertEqual(
            viewModel.currentStreak.current, 1,
            "With a live meal today, streak must be 1 even without a snapshot"
        )
    }
}
