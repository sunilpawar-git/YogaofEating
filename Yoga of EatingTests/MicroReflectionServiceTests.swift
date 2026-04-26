import XCTest
@testable import Yoga_of_Eating

final class MicroReflectionServiceTests: XCTestCase {
    // MARK: - Meal Codable Tests

    func testMealCodableRoundTripWithMicroReflection() throws {
        let meal = Meal(
            mealType: .lunch,
            items: ["Rice"],
            healthScore: 0.7,
            preHunger: 3,
            postSatisfaction: 2
        )

        let data = try JSONEncoder().encode(meal)
        let decoded = try JSONDecoder().decode(Meal.self, from: data)

        XCTAssertEqual(decoded.preHunger, 3)
        XCTAssertEqual(decoded.postSatisfaction, 2)
        XCTAssertEqual(decoded.items, ["Rice"])
    }

    func testMealCodableBackwardCompatNilFields() throws {
        let json = """
        {
            "id": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
            "timestamp": 1000000,
            "mealType": "lunch",
            "items": ["Rice"],
            "healthScore": 0.7,
            "isAIAnalyzed": false
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Meal.self, from: json)

        XCTAssertNil(decoded.preHunger)
        XCTAssertNil(decoded.postSatisfaction)
        XCTAssertEqual(decoded.items, ["Rice"])
    }

    // MARK: - MicroReflectionService Insight Tests

    func testInsightReturnsNilWhenAllRatingsNil() {
        let meals = [
            Meal(mealType: .lunch, items: ["Rice"]),
            Meal(mealType: .dinner, items: ["Pasta"]),
            Meal(mealType: .breakfast, items: ["Toast"])
        ]

        let result = MicroReflectionService.insight(for: meals)

        XCTAssertNil(result)
    }

    func testInsightReturnsNilWhenFewerThanThreeRated() {
        let meals = [
            Meal(
                mealType: .lunch, items: ["Rice"],
                preHunger: 4, postSatisfaction: 2
            ),
            Meal(
                mealType: .dinner, items: ["Pasta"],
                preHunger: 3, postSatisfaction: 1
            )
        ]

        let result = MicroReflectionService.insight(for: meals)

        XCTAssertNil(result)
    }

    func testInsightReturnsOvereatingHint() {
        let meals = [
            Meal(
                mealType: .lunch, items: ["Rice"],
                preHunger: 4, postSatisfaction: 2
            ),
            Meal(
                mealType: .dinner, items: ["Pasta"],
                preHunger: 5, postSatisfaction: 2
            ),
            Meal(
                mealType: .breakfast, items: ["Toast"],
                preHunger: 4, postSatisfaction: 1
            )
        ]

        let result = MicroReflectionService.insight(for: meals)

        XCTAssertNotNil(result)
        XCTAssertEqual(result, Strings.MicroReflection.overeatingHint)
    }

    func testInsightReturnsNilWhenRatingsBalanced() {
        let meals = [
            Meal(
                mealType: .lunch, items: ["Rice"],
                preHunger: 3, postSatisfaction: 3
            ),
            Meal(
                mealType: .dinner, items: ["Pasta"],
                preHunger: 4, postSatisfaction: 4
            ),
            Meal(
                mealType: .breakfast, items: ["Toast"],
                preHunger: 3, postSatisfaction: 3
            )
        ]

        let result = MicroReflectionService.insight(for: meals)

        XCTAssertNil(result)
    }

    // MARK: - Integration: ViewModel

    @MainActor
    func testSaveMicroReflectionUpdatesCorrectMeal() {
        let viewModel = MainViewModel(
            logicService: MockMealLogicService(),
            persistenceService: MockPersistenceService(),
            historicalService: MockHistoricalDataService()
        )

        viewModel.createNewMeal(mealType: .lunch)
        viewModel.createNewMeal(mealType: .dinner)

        let lunchId = viewModel.meals[0].id
        let dinnerId = viewModel.meals[1].id

        viewModel.saveMicroReflection(
            mealId: lunchId, preHunger: 4, postSatisfaction: 2
        )

        XCTAssertEqual(viewModel.meals[0].preHunger, 4)
        XCTAssertEqual(viewModel.meals[0].postSatisfaction, 2)
        XCTAssertNil(viewModel.meals[1].preHunger)
        XCTAssertNil(viewModel.meals[1].postSatisfaction)

        viewModel.saveMicroReflection(
            mealId: dinnerId, preHunger: 3, postSatisfaction: nil
        )

        XCTAssertEqual(viewModel.meals[1].preHunger, 3)
        XCTAssertNil(viewModel.meals[1].postSatisfaction)
    }

    @MainActor
    func testIntegrationInsightAfterSaveMicroReflection() {
        let viewModel = MainViewModel(
            logicService: MockMealLogicService(),
            persistenceService: MockPersistenceService(),
            historicalService: MockHistoricalDataService()
        )

        for _ in 0..<3 {
            viewModel.createNewMeal(mealType: .lunch)
        }

        for idx in 0..<3 {
            viewModel.saveMicroReflection(
                mealId: viewModel.meals[idx].id,
                preHunger: 5,
                postSatisfaction: 2
            )
        }

        let insight = MicroReflectionService.insight(for: viewModel.meals)

        XCTAssertNotNil(insight)
    }
}
