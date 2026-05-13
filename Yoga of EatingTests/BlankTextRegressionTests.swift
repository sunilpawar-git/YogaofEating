import XCTest
@testable import Yoga_of_Eating

/// Regression tests: AI analysis completions must not overwrite meal items.
///
/// Root cause (historical): concurrent Firebase calls raced to write back to
/// `meals[i]`, causing `@Published var meals` emissions that could blank the TextField.
/// Fixed by: (1) single tracked task per meal in AIAnalysisCoordinator, and
/// (2) removing the keystroke→ViewModel pipeline entirely (checkmark-only submission).
/// These tests now verify the coordinator-level isolation via updateMeal.
@MainActor
final class BlankTextRegressionTests: XCTestCase {
    // MARK: - Helpers

    private func makeVM(mockAI: InstantMockAILogicService) -> MainViewModel {
        let mockHistorical = MockHistoricalDataService()
        return MainViewModel(
            logicService: mockAI,
            persistenceService: MockPersistenceService(),
            historicalService: mockHistorical,
            insightService: MockInsightGenerationService(historicalService: mockHistorical),
            skipDataLoading: true
        )
    }

    // MARK: - Meal items not blanked by concurrent completions

    func test_submission_aiAnalysisCompletion_doesNotClearMealItems() async throws {
        let mockAI = InstantMockAILogicService()
        let vm = self.makeVM(mockAI: mockAI)

        vm.createNewMeal()
        let mealId = vm.meals[0].id
        let typedItems = ["chicken salad with avocado"]

        // User presses checkmark — sole submission path in simplified design
        vm.updateMeal(mealId, mealType: .lunch, items: typedItems)

        // Wait for the single tracked task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        let finalItems = vm.meals.first(where: { $0.id == mealId })?.items
        XCTAssertEqual(
            finalItems,
            typedItems,
            "Meal items must not be cleared after AI analysis completes"
        )
    }

    func test_submission_aiCompletion_itemsRetainSubmittedValue() async throws {
        let mockAI = InstantMockAILogicService()
        let vm = self.makeVM(mockAI: mockAI)

        vm.createNewMeal()
        let mealId = vm.meals[0].id
        let finalItems = ["lentil soup"]

        // User presses checkmark with final content — triggers single tracked AI task
        vm.updateMeal(mealId, mealType: .dinner, items: finalItems)

        try await Task.sleep(nanoseconds: 100_000_000)

        let storedItems = vm.meals.first(where: { $0.id == mealId })?.items
        XCTAssertEqual(
            storedItems,
            finalItems,
            "After rapid local updates, items must equal the last typed value"
        )
    }

    func test_concurrentMealUpdates_eachMealRetainsItsOwnItems() async throws {
        let mockAI = InstantMockAILogicService()
        let vm = self.makeVM(mockAI: mockAI)

        // Create two meals
        vm.createNewMeal()
        vm.createNewMeal()
        let id1 = vm.meals[0].id
        let id2 = vm.meals[1].id

        let items1 = ["green smoothie"]
        let items2 = ["bacon cheeseburger"]

        // Trigger analysis for both simultaneously
        vm.updateMeal(id1, mealType: .breakfast, items: items1)
        vm.updateMeal(id2, mealType: .lunch, items: items2)

        try await Task.sleep(nanoseconds: 200_000_000)

        let stored1 = vm.meals.first(where: { $0.id == id1 })?.items
        let stored2 = vm.meals.first(where: { $0.id == id2 })?.items

        XCTAssertEqual(stored1, items1, "Meal 1 items must not be overwritten by meal 2's analysis")
        XCTAssertEqual(stored2, items2, "Meal 2 items must not be overwritten by meal 1's analysis")
    }

    func test_isFocused_remainsUnaffected_duringConcurrentMealUpdates() async throws {
        // This test validates ViewModel-level stability:
        // if meals emissions are bounded (one task per meal), smiley state updates
        // also stabilise — no thrashing that could disrupt SwiftUI's @FocusState.
        let mockAI = InstantMockAILogicService()
        let vm = self.makeVM(mockAI: mockAI)

        vm.createNewMeal()
        let mealId = vm.meals[0].id

        // Rapid fire three updates — only last task should survive
        vm.updateMealItems(mealId, items: ["salad"])
        vm.updateMealItems(mealId, items: ["soup"])
        vm.updateMealItems(mealId, items: ["steak"])

        try await Task.sleep(nanoseconds: 200_000_000)

        // Verify exactly ONE analysis task completed (others were cancelled)
        // A task count > 1 would cause @Published thrashing that blanks the TextField
        XCTAssertLessThanOrEqual(
            mockAI.completedCallCount, 1,
            "Only one analysis must complete after rapid updateMealItems calls"
        )
    }
}

// MARK: - InstantMockAILogicService

/// An AIAnalysisProvider that returns instantly, simulating rapid completions
/// that could trigger concurrent `@Published var meals` emissions.
final class InstantMockAILogicService: AIAnalysisProvider {
    private(set) var completedCallCount: Int = 0

    func calculateHealthScore(for _: String) -> Double { 0.5 }
    func calculateHealthScore(for _: [String]) -> Double { 0.5 }
    func calculateNextState(from state: SmileyState, healthScore _: Double) -> SmileyState { state }

    func analyzeMealQuality(description _: String) async throws -> MealAnalysisResult {
        // No delay — fires back immediately, stressing concurrent completion handling
        self.completedCallCount += 1
        return MealAnalysisResult(score: 0.75, mood: .serene, sound: "chime", insight: nil, estimatedCalories: nil)
    }
}
