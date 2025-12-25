#if canImport(XCTest)
import XCTest

@MainActor
final class MainViewModelTests: XCTestCase {
    var sut: MainViewModel!
    var mockLogic: MockMealLogicService!
    
    override func setUp() {
        super.setUp()
        mockLogic = MockMealLogicService()
        sut = MainViewModel(logicService: mockLogic)
    }
    
    override func tearDown() {
        sut = nil
        mockLogic = nil
        super.tearDown()
    }
    
    func test_initialState_isNeutral() {
        XCTAssertEqual(sut.smileyState.scale, 1.0)
        XCTAssertEqual(sut.smileyState.mood, .serene)
        XCTAssertTrue(sut.meals.isEmpty)
    }
    
    func test_addingMeal_updatesStateAndMeals() {
        mockLogic.mockScore = 0.9
        mockLogic.nextState = SmileyState(scale: 0.9, mood: .serene)
        
        sut.createNewMeal()
        guard let mealId = sut.meals.first?.id else {
            XCTFail("Meal not created")
            return
        }
        
        sut.updateMeal(mealId, description: "Salad")
        
        XCTAssertEqual(sut.meals.count, 1)
        XCTAssertEqual(sut.meals.first?.description, "Salad")
        XCTAssertEqual(sut.smileyState.scale, 0.9)
    }
}

// Simple Mock for Testing
class MockMealLogicService: MealLogicProvider {
    var mockScore: Double = 0.5
    var nextState = SmileyState.neutral
    
    func calculateHealthScore(for description: String) -> Double {
        return mockScore
    }
    
    func calculateNextState(from currentState: SmileyState, healthScore: Double) -> SmileyState {
        return nextState
    }
}

#endif
