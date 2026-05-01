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

        // MARK: - Phase B4: SmileyScaleConstants Tests

        func test_calculateNextState_healthyScore_shrinksScale() {
            // Arrange: scale starts above floor
            let initialState = SmileyState(scale: 1.5, mood: .neutral)
            let healthyScore = ScoringThresholds.healthy + 0.1 // above threshold

            // Act
            let nextState = self.sut.calculateNextState(from: initialState, healthScore: healthyScore)

            // Assert: scale should have shrunk
            XCTAssertLessThan(nextState.scale, initialState.scale)
            XCTAssertEqual(nextState.mood, .serene)
        }

        func test_calculateNextState_unhealthyScore_growsScale() {
            // Arrange
            let initialState = SmileyState(scale: 1.0, mood: .neutral)
            let unhealthyScore = ScoringThresholds.unhealthy - 0.1 // below threshold

            // Act
            let nextState = self.sut.calculateNextState(from: initialState, healthScore: unhealthyScore)

            // Assert: scale should have grown
            XCTAssertGreaterThan(nextState.scale, initialState.scale)
            XCTAssertEqual(nextState.mood, .overwhelmed)
        }

        func test_calculateNextState_neutralScore_driftsToward1() {
            // Arrange: scale above 1.0 with neutral score should drift down
            let initialState = SmileyState(scale: 1.3, mood: .overwhelmed)
            let neutralScore = ScoringThresholds.neutral // exactly 0.5

            // Act
            let nextState = self.sut.calculateNextState(from: initialState, healthScore: neutralScore)

            // Assert: scale drifts toward 1.0 (decreases when above 1.0)
            XCTAssertLessThan(nextState.scale, initialState.scale)
            XCTAssertEqual(nextState.mood, .neutral)
        }
    }

#endif
