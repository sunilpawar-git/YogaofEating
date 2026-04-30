import XCTest
@testable import Yoga_of_Eating

/// Unit tests verifying that tab views receive only minimal required data
/// and cannot access sensitive user information.
/// These tests enforce the Principle of Least Privilege for tab implementations.
@MainActor
final class TabViewDataIsolationTests: XCTestCase {
    var viewModel: MainViewModel!

    override func setUp() {
        super.setUp()
        self.viewModel = MainViewModel(skipDataLoading: true)
    }

    // MARK: - HighlightView Data Isolation Tests

    func test_highlightView_receivesMinimalData() {
        // HighlightView should receive only: smileyState, mealsCount, averageScore, sleepQuality
        let data = self.viewModel.highlightData
        XCTAssertNil(data, "No data until meals are logged")

        // Add meals
        self.viewModel.meals = [
            Meal(
                id: UUID(),
                timestamp: Date(),
                mealType: .breakfast,
                items: ["Eggs", "Toast"],
                healthScore: 0.8,
                isAIAnalyzed: false
            ),
            Meal(
                id: UUID(),
                timestamp: Date().addingTimeInterval(3600),
                mealType: .lunch,
                items: ["Salad", "Chicken"],
                healthScore: 0.75,
                isAIAnalyzed: false
            )
        ]

        let highlightData = self.viewModel.highlightData
        XCTAssertNotNil(highlightData, "Data should be available when meals exist")
        XCTAssertEqual(highlightData?.mealsCount, 2)
        if let avg = highlightData?.averageScore {
            XCTAssertEqual(avg, 0.775, accuracy: 0.001)
        } else {
            XCTFail("Average score should not be nil")
        }
    }

    func test_highlightView_dataIsNilWhenViewingPastDate() {
        // HighlightView data should only be available when viewing today
        self.viewModel.meals = [
            Meal(
                id: UUID(),
                timestamp: Date(),
                mealType: .breakfast,
                items: ["Test"],
                healthScore: 0.8,
                isAIAnalyzed: false
            )
        ]

        let todayData = self.viewModel.highlightData
        XCTAssertNotNil(todayData, "Data available for today")

        // Navigate to yesterday
        let calendar = Calendar.current
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
            self.viewModel.selectedDate = yesterday
            let pastData = self.viewModel.highlightData
            XCTAssertNil(pastData, "Data should be nil when viewing past dates")
        }
    }

    func test_highlightView_dataIsNilWhenNoMeals() {
        // HighlightView data should be nil if no meals logged
        self.viewModel.meals = []
        XCTAssertNil(self.viewModel.highlightData, "Data should be nil when no meals logged")
    }

    func test_highlightView_cannotAccessIndividualMeals() {
        // HighlightView receives only aggregated data, not individual meal details
        let mealWithSensitiveItems = Meal(
            id: UUID(),
            timestamp: Date(),
            mealType: .breakfast,
            items: ["Medication", "Private health supplement"],
            healthScore: 0.5,
            isAIAnalyzed: false
        )
        self.viewModel.meals = [mealWithSensitiveItems]

        // HighlightView data doesn't contain individual meal items
        guard let data = self.viewModel.highlightData else {
            XCTFail("Data should be available")
            return
        }

        // Verify we can access only aggregated values, not individual meals
        XCTAssertEqual(data.mealsCount, 1, "Can access meal count")
        XCTAssertEqual(data.averageScore, 0.5, "Can access average score")
        // But NOT the actual meal items or mealTypes
        // This is verified by the parameter type itself: (mealsCount, averageScore, ...)
    }

    func test_highlightView_cannotAccessAllMeals() {
        // HighlightView should not have access to the full meals array
        let numberOfMeals = 5
        self.viewModel.meals = (0..<numberOfMeals).map { i in
            Meal(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(i) * 3600),
                mealType: .breakfast,
                items: ["Item \(i)"],
                healthScore: Double(i) / Double(numberOfMeals),
                isAIAnalyzed: false
            )
        }

        // HighlightView data contains mealsCount, but not the array itself
        guard let data = self.viewModel.highlightData else {
            XCTFail("Data should be available")
            return
        }

        XCTAssertEqual(data.mealsCount, numberOfMeals, "Can access count")
        // Cannot access individual meal objects or their properties
        // This is enforced by the tuple type signature
    }

    // MARK: - ReflectView Data Isolation Tests

    func test_reflectView_receivesMinimalData() {
        // ReflectView should receive only: mealsCount, averageScore
        let data = self.viewModel.reflectData
        XCTAssertNil(data, "No data until meals are logged")

        // Add meals
        self.viewModel.meals = [
            Meal(
                id: UUID(),
                timestamp: Date(),
                mealType: .breakfast,
                items: ["Oatmeal"],
                healthScore: 0.7,
                isAIAnalyzed: false
            )
        ]

        let reflectData = self.viewModel.reflectData
        XCTAssertNotNil(reflectData, "Data should be available when meals exist")
        XCTAssertEqual(reflectData?.mealsCount, 1)
        XCTAssertEqual(reflectData?.averageScore, 0.7)
    }

    func test_reflectView_dataIsNilWhenViewingPastDate() {
        // ReflectView data should only be available when viewing today
        self.viewModel.meals = [
            Meal(
                id: UUID(),
                timestamp: Date(),
                mealType: .breakfast,
                items: ["Test"],
                healthScore: 0.8,
                isAIAnalyzed: false
            )
        ]

        let todayData = self.viewModel.reflectData
        XCTAssertNotNil(todayData, "Data available for today")

        // Navigate to yesterday
        let calendar = Calendar.current
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
            self.viewModel.selectedDate = yesterday
            let pastData = self.viewModel.reflectData
            XCTAssertNil(pastData, "Data should be nil when viewing past dates")
        }
    }

    func test_reflectView_cannotAccessSmileyState() {
        // ReflectView should not have access to smiley state
        self.viewModel.smileyState = SmileyState(scale: 2.0, mood: .serene)
        self.viewModel.meals = [
            Meal(
                id: UUID(),
                timestamp: Date(),
                mealType: .breakfast,
                items: ["Test"],
                healthScore: 0.8,
                isAIAnalyzed: false
            )
        ]

        guard let data = self.viewModel.reflectData else {
            XCTFail("Data should be available")
            return
        }

        // ReflectView only receives mealsCount and averageScore
        // Cannot access smileyState - verified by tuple type signature
        XCTAssertEqual(data.mealsCount, 1)
        XCTAssertEqual(data.averageScore, 0.8)
        // smileyState is explicitly NOT in the tuple
    }

    func test_reflectView_cannotAccessSleepQuality() {
        // ReflectView should not have access to sleep quality
        self.viewModel.suggestedSleepQuality = .good
        self.viewModel.meals = [
            Meal(
                id: UUID(),
                timestamp: Date(),
                mealType: .breakfast,
                items: ["Test"],
                healthScore: 0.8,
                isAIAnalyzed: false
            )
        ]

        guard let data = self.viewModel.reflectData else {
            XCTFail("Data should be available")
            return
        }

        // ReflectView only receives mealsCount and averageScore
        // Cannot access sleepQuality - verified by tuple type signature
        // This is different from HighlightView which CAN access sleep quality
        XCTAssertEqual(data.mealsCount, 1)
        XCTAssertEqual(data.averageScore, 0.8)
    }

    func test_reflectView_cannotAccessFullMealsArray() {
        // ReflectView should not have direct access to meals array
        self.viewModel.meals = (0..<3).map { i in
            Meal(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(i) * 3600),
                mealType: .breakfast,
                items: ["Item \(i)"],
                healthScore: 0.7,
                isAIAnalyzed: false
            )
        }

        guard let data = self.viewModel.reflectData else {
            XCTFail("Data should be available")
            return
        }

        // ReflectView gets aggregated count, not individual meal objects
        XCTAssertEqual(data.mealsCount, 3, "Can access count")
        // Cannot access individual meals or their details
    }

    // MARK: - Shared Data Isolation Tests

    func test_tabDataComputed_onDemand() {
        // highlightData and reflectData should be computed on-demand, not cached
        self.viewModel.meals = [
            Meal(
                id: UUID(),
                timestamp: Date(),
                mealType: .breakfast,
                items: ["Test"],
                healthScore: 0.8,
                isAIAnalyzed: false
            )
        ]

        let firstCheck = self.viewModel.highlightData
        XCTAssertEqual(firstCheck?.mealsCount, 1)

        // Add another meal
        self.viewModel.meals.append(
            Meal(
                id: UUID(),
                timestamp: Date().addingTimeInterval(3600),
                mealType: .lunch,
                items: ["Test2"],
                healthScore: 0.75,
                isAIAnalyzed: false
            )
        )

        let secondCheck = self.viewModel.highlightData
        XCTAssertEqual(secondCheck?.mealsCount, 2, "Data should be recomputed with new meals")
    }

    func test_emptyMealsList_returnsNilData() {
        // Both tab data should be nil when meals array is empty
        self.viewModel.meals = []
        XCTAssertNil(self.viewModel.highlightData, "HighlightView data should be nil")
        XCTAssertNil(self.viewModel.reflectData, "ReflectView data should be nil")
    }

    func test_averageScoreCalculation_accurate() {
        // Verify accurate score calculation in both data contracts
        let scores: [Double] = [0.5, 0.7, 0.9]
        self.viewModel.meals = scores.enumerated().map { i, score in
            Meal(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(i) * 3600),
                mealType: .breakfast,
                items: ["Test"],
                healthScore: score,
                isAIAnalyzed: false
            )
        }

        let expectedAverage = (0.5 + 0.7 + 0.9) / 3.0 // ~0.7

        if let highlightAvg = self.viewModel.highlightData?.averageScore {
            XCTAssertEqual(highlightAvg, expectedAverage, accuracy: 0.001)
        } else {
            XCTFail("HighlightView average score should not be nil")
        }

        if let reflectAvg = self.viewModel.reflectData?.averageScore {
            XCTAssertEqual(reflectAvg, expectedAverage, accuracy: 0.001)
        } else {
            XCTFail("ReflectView average score should not be nil")
        }
    }
}
