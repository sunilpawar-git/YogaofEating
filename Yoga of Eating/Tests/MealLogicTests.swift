#if canImport(XCTest)
import XCTest

final class MealLogicTests: XCTestCase {
    var sut: MealLogicService!
    
    override func setUp() {
        super.setUp()
        sut = MealLogicService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func test_healthScore_forHealthyFood_isHigh() {
        let score = sut.calculateHealthScore(for: "Green salad with avocado")
        XCTAssertGreaterThanOrEqual(score, 0.8)
    }
    
    func test_healthScore_forUnhealthyFood_isLow() {
        let score = sut.calculateHealthScore(for: "Double cheeseburger and fries")
        XCTAssertLessThanOrEqual(score, 0.3)
    }
    
    func test_smileyScale_shrinks_whenHealthScoreIsHigh() {
        let initialState = SmileyState.neutral
        let newState = sut.calculateNextState(from: initialState, healthScore: 0.9)
        
        XCTAssertLessThan(newState.scale, initialState.scale)
        XCTAssertEqual(newState.mood, .serene)
    }
    
    func test_smileyScale_bloats_whenHealthScoreIsLow() {
        let initialState = SmileyState.neutral
        let newState = sut.calculateNextState(from: initialState, healthScore: 0.2)
        
        XCTAssertGreaterThan(newState.scale, initialState.scale)
        XCTAssertEqual(newState.mood, .overwhelmed)
    }
    
    func test_smileyMood_isNeutral_forAverageFood() {
        let initialState = SmileyState.neutral
        let newState = sut.calculateNextState(from: initialState, healthScore: 0.5)
        
        XCTAssertEqual(newState.mood, .neutral)
    }
}

#endif
