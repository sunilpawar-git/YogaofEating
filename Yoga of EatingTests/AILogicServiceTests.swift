#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    // NOTE: These tests use the MealLogicService instead of AILogicService
    // because AILogicService requires Firebase Functions which is not available
    // in the test environment without full Firebase configuration.

    final class AILogicServiceTests: XCTestCase {
        // MARK: - Properties

        var sut: MealLogicService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            // Use MealLogicService for testing the core logic
            // AILogicService would require Firebase to be configured
            self.sut = MealLogicService()
        }

        override func tearDown() {
            self.sut = nil
            super.tearDown()
        }

        // MARK: - Tests: Health Score Calculation

        func test_calculateHealthScore_returnsHalfScore_forString() {
            // Act
            let score = self.sut.calculateHealthScore(for: "apple")

            // Assert - MealLogicService returns 0.5 as default
            XCTAssertEqual(score, 0.5)
        }

        func test_calculateHealthScore_returnsHalfScore_forArray() {
            // Act
            let score = self.sut.calculateHealthScore(for: ["apple", "banana"])

            // Assert
            XCTAssertEqual(score, 0.5)
        }

        func test_calculateNextState_shrinksSmiley_forHealthyScore() {
            // Arrange
            let initialState = SmileyState(scale: 1.5, mood: .neutral)
            let healthScore = 0.7

            // Act
            let nextState = self.sut.calculateNextState(from: initialState, healthScore: healthScore)

            // Assert
            XCTAssertLessThan(nextState.scale, initialState.scale)
            XCTAssertEqual(nextState.mood, .serene)
        }

        func test_calculateNextState_bloatsSmiley_forUnhealthyScore() {
            // Arrange
            let initialState = SmileyState(scale: 1.0, mood: .neutral)
            let healthScore = 0.3

            // Act
            let nextState = self.sut.calculateNextState(from: initialState, healthScore: healthScore)

            // Assert
            XCTAssertGreaterThan(nextState.scale, initialState.scale)
            XCTAssertEqual(nextState.mood, .overwhelmed)
        }

        func test_calculateNextState_clampsScale_atMaximum() {
            // Arrange
            let initialState = SmileyState(scale: 2.4, mood: .overwhelmed)
            let healthScore = 0.2

            // Act
            let nextState = self.sut.calculateNextState(from: initialState, healthScore: healthScore)

            // Assert
            XCTAssertLessThanOrEqual(nextState.scale, 2.5)
        }

        func test_calculateNextState_clampsScale_atMinimum() {
            // Arrange
            let initialState = SmileyState(scale: 0.6, mood: .serene)
            let healthScore = 0.8

            // Act
            let nextState = self.sut.calculateNextState(from: initialState, healthScore: healthScore)

            // Assert
            XCTAssertGreaterThanOrEqual(nextState.scale, 0.5)
        }

        // NOTE: The async Firebase tests (analyzeMealQuality) are omitted because
        // AILogicService requires Firebase Functions to be configured. Integration
        // tests with Firebase Emulator Suite would be needed to test this functionality.
    }
#endif
