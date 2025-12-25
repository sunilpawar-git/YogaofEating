#if canImport(XCTest)
    import XCTest

    @MainActor
    final class MainViewModelTests: XCTestCase {
        var sut: MainViewModel!
        var mockLogic: MockMealLogicService!

        override func setUp() {
            super.setUp()
            self.mockLogic = MockMealLogicService()
            self.sut = MainViewModel(logicService: self.mockLogic)
        }

        override func tearDown() {
            self.sut = nil
            self.mockLogic = nil
            super.tearDown()
        }

        func test_initialState_isNeutral() {
            XCTAssertEqual(self.sut.smileyState.scale, 1.0)
            XCTAssertEqual(self.sut.smileyState.mood, .serene)
            XCTAssertTrue(self.sut.meals.isEmpty)
        }

        func test_addingMeal_updatesStateAndMeals() {
            self.mockLogic.mockScore = 0.9
            self.mockLogic.nextState = SmileyState(scale: 0.9, mood: .serene)

            self.sut.createNewMeal()
            guard let mealId = sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            self.sut.updateMeal(mealId, description: "Salad")

            XCTAssertEqual(self.sut.meals.count, 1)
            XCTAssertEqual(self.sut.meals.first?.description, "Salad")
            XCTAssertEqual(self.sut.smileyState.scale, 0.9)
        }
    }

    // Simple Mock for Testing
    class MockMealLogicService: MealLogicProvider {
        var mockScore: Double = 0.5
        var nextState = SmileyState.neutral

        func calculateHealthScore(for _: String) -> Double {
            self.mockScore
        }

        func calculateHealthScore(for items: [String]) -> Double {
            guard !items.isEmpty else { return 0.5 }
            return self.mockScore
        }

        func calculateNextState(from _: SmileyState, healthScore _: Double) -> SmileyState {
            self.nextState
        }
    }

#endif
