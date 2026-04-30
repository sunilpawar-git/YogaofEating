import XCTest
@testable import Yoga_of_Eating

/// Tests for the day summary line and background glow constants (Phase 5).
@MainActor
final class DaySummaryTests: XCTestCase {
    // MARK: - Strings.Timeline.daySummary

    func test_daySummary_singleMeal_usesSingular() {
        let result = Strings.Timeline.daySummary(avgScore: 80, mealCount: 1)
        XCTAssertTrue(result.contains("meal ") || result.hasSuffix("meal"), "Should use singular: got \(result)")
        XCTAssertFalse(result.contains("meals"), "Should not use plural for 1 meal: got \(result)")
    }

    func test_daySummary_multipleMeals_usesPlural() {
        let result = Strings.Timeline.daySummary(avgScore: 75, mealCount: 3)
        XCTAssertTrue(result.contains("meals"), "Should use plural: got \(result)")
    }

    func test_daySummary_includesScore() {
        let result = Strings.Timeline.daySummary(avgScore: 76, mealCount: 3)
        XCTAssertTrue(result.contains("76%"), "Should contain score percentage: got \(result)")
    }

    func test_daySummary_includesMealCount() {
        let result = Strings.Timeline.daySummary(avgScore: 80, mealCount: 2)
        XCTAssertTrue(result.contains("2"), "Should contain meal count: got \(result)")
    }

    func test_daySummary_isNotEmpty() {
        let result = Strings.Timeline.daySummary(avgScore: 0, mealCount: 1)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - averageHealthScoreToday ViewModel property

    func test_averageHealthScoreToday_noMeals_returnsNil() throws {
        let vm = try XCTUnwrap(makeViewModel())
        // When: no meals
        // Then: nil (fewer than 2 meals — summary line not shown)
        XCTAssertNil(vm.averageHealthScoreToday)
    }

    func test_averageHealthScoreToday_oneMeal_returnsNil() throws {
        let vm = try XCTUnwrap(makeViewModel())
        // Given: exactly 1 meal — below the 2-meal display threshold
        vm.meals = [Meal(mealType: .breakfast, items: ["Oats"], healthScore: 0.8)]
        // Then: nil (summary line requires >= 2 meals)
        XCTAssertNil(vm.averageHealthScoreToday)
    }

    func test_averageHealthScoreToday_twoMeals_returnsAverage() throws {
        let vm = try XCTUnwrap(makeViewModel())
        // Given: exactly 2 meals — threshold met
        vm.meals = [
            Meal(mealType: .breakfast, items: ["Oats"], healthScore: 0.8),
            Meal(mealType: .lunch, items: ["Salad"], healthScore: 0.6)
        ]
        // Then: average of 0.8 and 0.6 = 0.7
        let result = try XCTUnwrap(vm.averageHealthScoreToday)
        XCTAssertEqual(result, 0.7, accuracy: 0.001)
    }

    func test_averageHealthScoreToday_threeMeals_returnsCorrectAverage() throws {
        let vm = try XCTUnwrap(makeViewModel())
        // Given: 3 meals
        vm.meals = [
            Meal(mealType: .breakfast, items: ["Oats"], healthScore: 1.0),
            Meal(mealType: .lunch, items: ["Salad"], healthScore: 0.5),
            Meal(mealType: .dinner, items: ["Steak"], healthScore: 0.0)
        ]
        // Then: average = (1.0 + 0.5 + 0.0) / 3 = 0.5
        let result = try XCTUnwrap(vm.averageHealthScoreToday)
        XCTAssertEqual(result, 0.5, accuracy: 0.001)
    }

    func test_averageHealthScoreToday_boundaryScores_returnsCorrectAverage() throws {
        let vm = try XCTUnwrap(makeViewModel())
        // Given: two meals at boundary values
        vm.meals = [
            Meal(mealType: .breakfast, items: ["A"], healthScore: 0.0),
            Meal(mealType: .lunch, items: ["B"], healthScore: 1.0)
        ]
        // Then: average = 0.5
        let result = try XCTUnwrap(vm.averageHealthScoreToday)
        XCTAssertEqual(result, 0.5, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func makeViewModel() -> MainViewModel? {
        let mockLogic = MockMealLogicService()
        let mockPersistence = MockPersistenceService()
        let mockHistorical = MockHistoricalDataService()
        return MainViewModel(
            logicService: mockLogic,
            persistenceService: mockPersistence,
            historicalService: mockHistorical,
            skipDataLoading: true
        )
    }
}
