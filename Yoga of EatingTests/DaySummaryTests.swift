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

    // MARK: - AppTheme.Background constants

    func test_background_glowOpacity_isCorrectValue() {
        XCTAssertEqual(AppTheme.Background.glowOpacity, 0.08, accuracy: 0.001)
    }

    func test_background_glowOpacity_isInValidRange() {
        let opacity = AppTheme.Background.glowOpacity
        XCTAssertGreaterThan(opacity, 0.0, "Glow must be visible")
        XCTAssertLessThan(opacity, 0.2, "Glow must not be heavy")
    }

    func test_background_glowBlurRadius_isCorrectValue() {
        XCTAssertEqual(AppTheme.Background.glowBlurRadius, 60, accuracy: 0.01)
    }

    func test_background_glowBlurRadius_isPositive() {
        XCTAssertGreaterThan(AppTheme.Background.glowBlurRadius, 0)
    }

    func test_background_glowSize_isPositive() {
        XCTAssertGreaterThan(AppTheme.Background.glowSize, 0)
    }

    func test_background_glowSize_isSmallerThanOldValue() {
        // Old value was 400pt — new value must be tighter
        XCTAssertLessThan(AppTheme.Background.glowSize, 400)
    }

    // MARK: - averageHealthScoreToday ViewModel property

    func test_averageHealthScoreToday_noMeals_returnsNil() throws {
        let vm = try XCTUnwrap(makeViewModel())
        // When: no meals
        // Then: nil (nothing to average)
        XCTAssertNil(vm.averageHealthScoreToday)
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
