import XCTest
@testable import Yoga_of_Eating

/// Phase 3B — AIAnalysisCoordinator unit tests.
///
/// Tests verify coordinator isolation, task lifecycle, and write-back closure
/// contracts. The coordinator must never hold a reference to MainViewModel —
/// only the `AIAnalysisContext` closures.
@MainActor
final class AIAnalysisCoordinatorTests: XCTestCase {
    // MARK: - Helpers

    private func makeCoordinator() -> AIAnalysisCoordinator {
        AIAnalysisCoordinator()
    }

    // MARK: - Task deduplication

    func test_analyzeIfNeeded_cancelsStaleTask_beforeStartingNew() async {
        let coordinator = self.makeCoordinator()
        let mock = SlowCoordinatorMockAI(delay: 2.0)

        let meal = MealBuilder().withItems(["salad"]).build()
        let ctx = AIAnalysisContext(
            logicService: mock,
            currentMealsSnapshot: [meal],
            onMealScoreUpdated: { _, _, _, _ in },
            onSmileyStateChanged: { _ in }
        )

        // Start first analysis
        coordinator.analyzeIfNeeded(mealId: meal.id, items: meal.items, in: ctx)
        let firstTask = coordinator.task(for: meal.id)

        // Immediately start second — should cancel first
        coordinator.analyzeIfNeeded(mealId: meal.id, items: ["burger"], in: ctx)

        await Task.yield()

        XCTAssertTrue(
            firstTask?.isCancelled == true,
            "First task must be cancelled when a new analysis starts for the same meal"
        )
    }

    func test_analyzeIfNeeded_tracksTaskForMeal() async {
        let coordinator = self.makeCoordinator()
        let mock = SlowCoordinatorMockAI(delay: 2.0)

        let meal = MealBuilder().withItems(["salad"]).build()
        let ctx = AIAnalysisContext(
            logicService: mock,
            currentMealsSnapshot: [meal],
            onMealScoreUpdated: { _, _, _, _ in },
            onSmileyStateChanged: { _ in }
        )

        coordinator.analyzeIfNeeded(mealId: meal.id, items: meal.items, in: ctx)

        XCTAssertNotNil(coordinator.task(for: meal.id), "Task must be tracked after analyzeIfNeeded")
    }

    func test_cancelAnalysis_cancelsInFlightTask() async {
        let coordinator = self.makeCoordinator()
        let mock = SlowCoordinatorMockAI(delay: 5.0)

        let meal = MealBuilder().withItems(["burger"]).build()
        let ctx = AIAnalysisContext(
            logicService: mock,
            currentMealsSnapshot: [meal],
            onMealScoreUpdated: { _, _, _, _ in },
            onSmileyStateChanged: { _ in }
        )

        coordinator.analyzeIfNeeded(mealId: meal.id, items: meal.items, in: ctx)
        let task = coordinator.task(for: meal.id)

        coordinator.cancelAnalysis(for: meal.id)
        await Task.yield()

        XCTAssertTrue(task?.isCancelled == true, "Task must be cancelled after cancelAnalysis(for:)")
    }

    // MARK: - Write-back closures

    func test_onMealScoreUpdated_isCalledAfterAnalysisCompletes() async {
        let coordinator = self.makeCoordinator()
        let mock = InstantCoordinatorMockAI(score: 0.9)

        var capturedId: UUID?
        var capturedScore: Double?

        let meal = MealBuilder().withItems(["green salad"]).build()
        let ctx = AIAnalysisContext(
            logicService: mock,
            currentMealsSnapshot: [meal],
            onMealScoreUpdated: { id, score, _, _ in
                capturedId = id
                capturedScore = score
            },
            onSmileyStateChanged: { _ in }
        )

        coordinator.analyzeIfNeeded(mealId: meal.id, items: meal.items, in: ctx)
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(capturedId, meal.id, "onMealScoreUpdated must receive the correct meal ID")
        XCTAssertEqual(
            capturedScore ?? 0.0,
            0.9,
            accuracy: 0.001,
            "onMealScoreUpdated must receive the score from the AI service"
        )
    }

    func test_onMealScoreUpdated_isCalledOnMainActor() async {
        let coordinator = self.makeCoordinator()
        let mock = InstantCoordinatorMockAI(score: 0.8)

        var calledOnMain = false
        let meal = MealBuilder().withItems(["fruit"]).build()
        let ctx = AIAnalysisContext(
            logicService: mock,
            currentMealsSnapshot: [meal],
            onMealScoreUpdated: { _, _, _, _ in
                // Thread.isMainThread is stable across Swift concurrency versions;
                // avoids the DEBUG-trap risk of MainActor.assumeIsolated.
                calledOnMain = Thread.isMainThread
            },
            onSmileyStateChanged: { _ in }
        )

        coordinator.analyzeIfNeeded(mealId: meal.id, items: meal.items, in: ctx)
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(calledOnMain, "onMealScoreUpdated must be called on @MainActor (main thread)")
    }
}

// MARK: - Test-local mocks

/// Slow mock that stays in-flight for task-lifecycle tests.
class SlowCoordinatorMockAI: AIAnalysisProvider {
    private let delay: Double
    init(delay: Double) { self.delay = delay }

    func calculateHealthScore(for _: String) -> Double { 0.5 }
    func calculateHealthScore(for _: [String]) -> Double { 0.5 }
    func calculateNextState(from state: SmileyState, healthScore _: Double) -> SmileyState { state }

    func analyzeMealQuality(description _: String) async throws -> MealAnalysisResult {
        try await Task.sleep(nanoseconds: UInt64(self.delay * 1_000_000_000))
        return MealAnalysisResult(score: 0.5, mood: .neutral, sound: "", insight: nil, estimatedCalories: nil)
    }
}

/// Instant mock for write-back closure tests.
class InstantCoordinatorMockAI: AIAnalysisProvider {
    private let score: Double
    init(score: Double) { self.score = score }

    func calculateHealthScore(for _: String) -> Double { self.score }
    func calculateHealthScore(for _: [String]) -> Double { self.score }
    func calculateNextState(from state: SmileyState, healthScore _: Double) -> SmileyState { state }

    func analyzeMealQuality(description _: String) async throws -> MealAnalysisResult {
        MealAnalysisResult(score: self.score, mood: .serene, sound: "chime", insight: nil, estimatedCalories: nil)
    }
}
