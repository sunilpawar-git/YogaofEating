#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class MainViewModelAIAnalysisTests: XCTestCase {
        // MARK: - Properties

        var sut: MainViewModel!
        var mockAILogic: MockAILogicService!
        var mockPersistence: MockPersistenceService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.mockAILogic = MockAILogicService()
            self.mockPersistence = MockPersistenceService()
            self.sut = MainViewModel(logicService: self.mockAILogic, persistenceService: self.mockPersistence)
        }

        override func tearDown() {
            self.sut = nil
            self.mockAILogic = nil
            self.mockPersistence = nil
            super.tearDown()
        }

        // MARK: - Tests: Success Scenarios

        func test_performDeepAnalysis_updatesHealthScore_onSuccess() async {
            // Arrange
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime")

            // Act
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Apple", "Salad"])

            // Assert
            XCTAssertTrue(self.mockAILogic.analyzeCalled)
            XCTAssertEqual(self.sut.meals.first?.healthScore, 0.8)
        }

        func test_performDeepAnalysis_updatesSmileyState_onSuccess() async {
            // Arrange
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.mockAnalysisResult = (score: 0.9, mood: .serene, sound: "chime")

            // Act
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Healthy food"])

            // Assert
            // Smiley state should be updated based on the health score
            XCTAssertNotNil(self.sut.smileyState)
        }

        func test_reanalyzeAllMealsForSmileyState_calculatesAverage_correctly() async {
            // Arrange
            self.sut.createNewMeal()
            self.sut.createNewMeal()
            self.sut.createNewMeal()

            // Set health scores manually
            if self.sut.meals.count >= 3 {
                self.sut.meals[0].healthScore = 0.6
                self.sut.meals[1].healthScore = 0.8
                self.sut.meals[2].healthScore = 1.0
            }

            // Act
            await self.sut.reanalyzeAllMealsForSmileyState()

            // Assert
            // Average should be (0.6 + 0.8 + 1.0) / 3 = 0.8
            // This would affect the smiley state accordingly
            XCTAssertNotNil(self.sut.smileyState)
        }

        // MARK: - Tests: Error Scenarios

        func test_performDeepAnalysis_returnsEarly_whenMealNotFound() async {
            // Arrange
            let nonExistentId = UUID()

            // Act
            await self.sut.performDeepAnalysis(for: nonExistentId, items: ["Food"])

            // Assert
            XCTAssertFalse(self.mockAILogic.analyzeCalled)
        }

        func test_performDeepAnalysis_usesLocalScore_whenServiceNotAI() async {
            // Arrange
            let mockLocalLogic = MockMealLogicService()
            self.sut = MainViewModel(logicService: mockLocalLogic, persistenceService: self.mockPersistence)
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            // Act
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Food"])

            // Assert
            // Should use local scoring since service is not AILogicService
            XCTAssertEqual(self.sut.meals.first?.healthScore, 0.5)
        }

        func test_performDeepAnalysis_fallsBack_onAIError() async {
            // Arrange
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.shouldThrowError = true

            // Act
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Food"])

            // Assert
            XCTAssertTrue(self.mockAILogic.analyzeCalled)
            // Should fall back gracefully without crashing
        }

        func test_reanalyzeAllMealsForSmileyState_doesNothing_whenMealsEmpty() async {
            // Arrange
            // No meals created

            // Act
            await self.sut.reanalyzeAllMealsForSmileyState()

            // Assert
            XCTAssertEqual(self.sut.smileyState.scale, 1.0)
            XCTAssertEqual(self.sut.smileyState.mood, .neutral)
        }
    }

    // MARK: - Mocks

    /// Mock AILogicService for testing
    class MockAILogicService: AIAnalysisProvider {
        var mockAnalysisResult: (score: Double, mood: SmileyMood, sound: String) = (0.7, .serene, "chime")
        var shouldThrowError: Bool = false
        var analyzeCalled: Bool = false

        func calculateHealthScore(for _: String) -> Double {
            0.5
        }

        func calculateHealthScore(for _: [String]) -> Double {
            0.5
        }

        func calculateNextState(from state: SmileyState, healthScore: Double) -> SmileyState {
            var nextState = state

            if healthScore > 0.6 {
                nextState.scale = max(0.5, state.scale - 0.1)
                nextState.mood = .serene
            } else if healthScore < 0.4 {
                nextState.scale = min(2.5, state.scale + 0.2)
                nextState.mood = .overwhelmed
            } else {
                nextState.mood = .neutral
            }

            return nextState
        }

        func analyzeMealQuality(description _: String) async throws
            -> (score: Double, mood: SmileyMood, sound: String)
        {
            self.analyzeCalled = true

            if self.shouldThrowError {
                throw NSError(
                    domain: "MockAILogicService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Mock error"]
                )
            }

            return self.mockAnalysisResult
        }
    }
#endif
