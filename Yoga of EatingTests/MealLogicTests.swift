#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class MealLogicTests: XCTestCase {
        var sut: MealLogicService!

        override func setUp() {
            super.setUp()
            self.sut = MealLogicService()
        }

        override func tearDown() {
            self.sut = nil
            super.tearDown()
        }

        func test_healthScore_forHealthyFood_isHigh() {
            let score = self.sut.calculateHealthScore(for: "Green salad with avocado")
            XCTAssertGreaterThanOrEqual(score, 0.79)
        }

        func test_healthScore_forUnhealthyFood_isLow() {
            let score = self.sut.calculateHealthScore(for: "Double cheeseburger and fries")
            XCTAssertLessThanOrEqual(score, 0.3)
        }

        func test_healthScore_forAverageFood_isNeutral() {
            let score = self.sut.calculateHealthScore(for: "Toast")
            XCTAssertEqual(score, 0.5)
        }

        func test_multiItem_healthScore_isAggregate() {
            let items = ["Salad", "Pizza"]
            // Salad (Healthy +0.1) -> 0.6
            // Pizza (Unhealthy -0.1) -> 0.4
            // Average -> 0.5
            let score = self.sut.calculateHealthScore(for: items)
            XCTAssertEqual(score, 0.5)
        }

        func test_multiItem_healthScore_forAllHealthy_isHigh() {
            let items = ["Salad", "Avocado", "Green Tea"]
            let score = self.sut.calculateHealthScore(for: items)
            XCTAssertGreaterThanOrEqual(score, 0.6)
        }

        func test_multiItem_healthScore_forEmptyList_isNeutral() {
            let score = self.sut.calculateHealthScore(for: [])
            XCTAssertEqual(score, 0.5)
        }

        func test_smileyScale_shrinks_whenHealthScoreIsHigh() {
            let initialState = SmileyState.neutral
            let newState = self.sut.calculateNextState(from: initialState, healthScore: 0.9)

            XCTAssertLessThan(newState.scale, initialState.scale)
            XCTAssertEqual(newState.mood, .serene)
        }

        func test_smileyScale_bloats_whenHealthScoreIsLow() {
            let initialState = SmileyState.neutral
            let newState = self.sut.calculateNextState(from: initialState, healthScore: 0.2)

            XCTAssertGreaterThan(newState.scale, initialState.scale)
            XCTAssertEqual(newState.mood, .overwhelmed)
        }

        func test_smileyMood_isNeutral_forAverageFood() {
            let initialState = SmileyState.neutral
            let newState = self.sut.calculateNextState(from: initialState, healthScore: 0.5)

            XCTAssertEqual(newState.mood, .neutral)
        }
    }

#endif
