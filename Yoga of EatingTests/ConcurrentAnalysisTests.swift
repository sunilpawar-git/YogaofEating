import XCTest
@testable import Yoga_of_Eating

/// Tests that rapid meal edits cancel previous in-flight AI analysis tasks,
/// preventing concurrent Firebase calls from racing and corrupting state.
///
/// After Phase 3B, task tracking moved from `MainViewModel.aiTasks` into
/// `AIAnalysisCoordinator`. These tests access tasks via `vm.aiCoordinator.task(for:)`.
@MainActor
final class ConcurrentAnalysisTests: XCTestCase {
    // MARK: - Helpers

    private func makeVM(mockAI: TrackingMockAILogicService) -> MainViewModel {
        let mockHistorical = MockHistoricalDataService()
        return MainViewModel(
            logicService: mockAI,
            persistenceService: MockPersistenceService(),
            historicalService: mockHistorical,
            skipDataLoading: true
        )
    }

    // MARK: - Phase 1a: updateMealItems uses coordinator for cancellation

    func test_updateMealItems_storesTaskInCoordinator() async throws {
        let mockAI = TrackingMockAILogicService(delay: 0.05)
        let vm = self.makeVM(mockAI: mockAI)

        vm.createNewMeal()
        let mealId = vm.meals[0].id

        vm.updateMealItems(mealId, items: ["salad"])

        // After calling updateMealItems, a task must be tracked in the coordinator
        XCTAssertNotNil(vm.aiCoordinator.task(for: mealId), "updateMealItems must store task in coordinator")
    }

    func test_updateMealItems_cancelsExistingTaskBeforeStartingNew() async throws {
        let mockAI = TrackingMockAILogicService(delay: 0.05)
        let vm = self.makeVM(mockAI: mockAI)

        vm.createNewMeal()
        let mealId = vm.meals[0].id

        // First call — starts a slow task
        vm.updateMealItems(mealId, items: ["pizza"])
        let firstTask = vm.aiCoordinator.task(for: mealId)

        // Second call before first finishes — must cancel first task
        vm.updateMealItems(mealId, items: ["salad"])

        // Give cancellation a moment to propagate
        try await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertTrue(
            firstTask?.isCancelled ?? false,
            "The first task must be cancelled when a new updateMealItems call arrives"
        )
    }

    func test_updateMealItems_rapidUpdates_onlyOneAnalysisRunsAtATime() async throws {
        let mockAI = TrackingMockAILogicService(delay: 0.05)
        let vm = self.makeVM(mockAI: mockAI)

        vm.createNewMeal()
        let mealId = vm.meals[0].id

        // Fire three rapid updates
        vm.updateMealItems(mealId, items: ["pizza"])
        vm.updateMealItems(mealId, items: ["burger"])
        vm.updateMealItems(mealId, items: ["salad"])

        // Wait for the last analysis to complete
        try await Task.sleep(nanoseconds: 200_000_000)

        // Only one non-cancelled call should complete successfully
        XCTAssertLessThanOrEqual(
            mockAI.completedCallCount, 1,
            "Only the last analysis should complete; earlier tasks must be cancelled"
        )
    }

    // MARK: - Phase 1b: updateMeal (contentChanged branch) uses coordinator

    func test_updateMeal_contentChanged_storesTaskInCoordinator() async throws {
        let mockAI = TrackingMockAILogicService(delay: 0.05)
        let vm = self.makeVM(mockAI: mockAI)

        vm.createNewMeal()
        let mealId = vm.meals[0].id

        vm.updateMeal(mealId, mealType: .lunch, items: ["salad"])

        XCTAssertNotNil(
            vm.aiCoordinator.task(for: mealId),
            "updateMeal (content changed) must store task in coordinator"
        )
    }

    func test_updateMeal_contentChanged_cancelsExistingTaskBeforeStartingNew() async throws {
        let mockAI = TrackingMockAILogicService(delay: 0.05)
        let vm = self.makeVM(mockAI: mockAI)

        vm.createNewMeal()
        let mealId = vm.meals[0].id

        vm.updateMeal(mealId, mealType: .lunch, items: ["pizza"])
        let firstTask = vm.aiCoordinator.task(for: mealId)

        vm.updateMeal(mealId, mealType: .lunch, items: ["salad"])

        try await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertTrue(
            firstTask?.isCancelled ?? false,
            "The first task must be cancelled when a new updateMeal content-change call arrives"
        )
    }

    // MARK: - Phase 1c: updateMeal (needsAIAnalysis branch) uses coordinator

    func test_updateMeal_needsAIAnalysis_storesTaskInCoordinator() async throws {
        let mockAI = TrackingMockAILogicService(delay: 0.05)
        let vm = self.makeVM(mockAI: mockAI)

        vm.createNewMeal()
        let mealId = vm.meals[0].id

        // Set meal type first so it won't change in subsequent calls (mealTypeChanged = false)
        vm.updateMeal(mealId, mealType: .lunch, items: ["salad"])

        // Wait for analysis to complete
        try await Task.sleep(nanoseconds: 300_000_000)

        // Mark as not-analyzed: needsAIAnalysis branch fires when same content + same mealType
        vm.meals[vm.meals.firstIndex(where: { $0.id == mealId })!].isAIAnalyzed = false

        vm.updateMeal(mealId, mealType: .lunch, items: ["salad"])

        XCTAssertNotNil(
            vm.aiCoordinator.task(for: mealId),
            "updateMeal (needsAIAnalysis) must store task in coordinator"
        )
    }

    func test_updateMeal_needsAIAnalysis_cancelsExistingTaskBeforeStartingNew() async throws {
        let mockAI = TrackingMockAILogicService(delay: 0.05)
        let vm = self.makeVM(mockAI: mockAI)

        vm.createNewMeal()
        let mealId = vm.meals[0].id

        // Establish mealType and initial analysis
        vm.updateMeal(mealId, mealType: .lunch, items: ["salad"])
        try await Task.sleep(nanoseconds: 300_000_000)

        // Fire first needsAIAnalysis task
        vm.meals[vm.meals.firstIndex(where: { $0.id == mealId })!].isAIAnalyzed = false
        vm.updateMeal(mealId, mealType: .lunch, items: ["salad"])
        let firstTask = vm.aiCoordinator.task(for: mealId)

        // Fire second immediately — should cancel first
        vm.meals[vm.meals.firstIndex(where: { $0.id == mealId })!].isAIAnalyzed = false
        vm.updateMeal(mealId, mealType: .lunch, items: ["salad"])

        try await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertTrue(
            firstTask?.isCancelled ?? false,
            "The first needsAIAnalysis task must be cancelled when a second one arrives"
        )
    }

    // MARK: - Phase 1d: coordinator clears task after analysis completes

    func test_coordinatorTask_clearedAfterAnalysisCompletes() async throws {
        let mockAI = TrackingMockAILogicService(delay: 0.01)
        let vm = self.makeVM(mockAI: mockAI)

        vm.createNewMeal()
        let mealId = vm.meals[0].id

        vm.updateMealItems(mealId, items: ["salad"])

        // Wait for analysis to complete
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertNil(
            vm.aiCoordinator.task(for: mealId),
            "Coordinator task entry must be cleared after analysis completes"
        )
    }
}

// MARK: - TrackingMockAILogicService

/// An AIAnalysisProvider mock that records how many calls complete (vs get cancelled).
/// Lives here because it's specific to concurrency tests.
final class TrackingMockAILogicService: AIAnalysisProvider {
    private let delay: TimeInterval
    private(set) var completedCallCount: Int = 0

    init(delay: TimeInterval) {
        self.delay = delay
    }

    func calculateHealthScore(for _: String) -> Double { 0.5 }
    func calculateHealthScore(for _: [String]) -> Double { 0.5 }
    func calculateNextState(from state: SmileyState, healthScore _: Double) -> SmileyState { state }

    func analyzeMealQuality(description _: String) async throws -> MealAnalysisResult {
        try await Task.sleep(nanoseconds: UInt64(self.delay * 1_000_000_000))
        self.completedCallCount += 1
        return MealAnalysisResult(score: 0.7, mood: .serene, sound: "chime", insight: nil, estimatedCalories: nil)
    }
}
