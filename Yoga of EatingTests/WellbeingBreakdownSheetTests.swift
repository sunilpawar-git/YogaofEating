import XCTest

@testable import Yoga_of_Eating

@MainActor
final class WellbeingBreakdownSheetTests: XCTestCase {
    var sut: MainViewModel!
    var mockHistorical: MockHistoricalDataService!
    var mockPersistence: MockPersistenceService!
    var mockLogic: MockMealLogicService!

    override func setUp() {
        super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        self.mockPersistence = MockPersistenceService()
        self.mockLogic = MockMealLogicService()
        self.sut = MainViewModel(
            logicService: self.mockLogic,
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            skipDataLoading: true
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockHistorical = nil
        self.mockPersistence = nil
        self.mockLogic = nil
        super.tearDown()
    }

    // MARK: - Contract Availability

    func test_wellbeingBreakdownContract_isNilWhenNoMeals() {
        XCTAssertNil(self.sut.wellbeingBreakdownContract)
    }

    func test_wellbeingBreakdownContract_isNotNilWithMealsToday() {
        self.sut.meals = [MealBuilder().build()]
        XCTAssertNotNil(self.sut.wellbeingBreakdownContract)
    }

    func test_wellbeingBreakdownContract_isNilWhenNotViewingToday() {
        self.sut.meals = [MealBuilder().build()]
        // Navigate to yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        self.sut.selectedDate = yesterday
        XCTAssertNil(self.sut.wellbeingBreakdownContract)
    }

    // MARK: - Contract Contents

    func test_wellbeingBreakdownContract_containsDimensions() {
        self.sut.meals = [MealBuilder().build()]
        let contract = self.sut.wellbeingBreakdownContract
        XCTAssertNotNil(contract?.dimensions)
    }

    func test_wellbeingBreakdownContract_containsDominantDimension() {
        self.sut.meals = [MealBuilder().build()]
        let contract = self.sut.wellbeingBreakdownContract
        XCTAssertNotNil(contract?.dominantDimension)
    }

    func test_wellbeingBreakdownContract_containsCausalNarrative() {
        self.sut.meals = [MealBuilder().build()]
        let contract = self.sut.wellbeingBreakdownContract
        XCTAssertFalse(contract?.causalNarrative.isEmpty ?? true)
    }

    func test_wellbeingBreakdownContract_weakDimensionsAtMostTwo() {
        self.sut.meals = [MealBuilder().build()]
        let contract = self.sut.wellbeingBreakdownContract
        XCTAssertLessThanOrEqual(contract?.weakDimensions.count ?? 0, 2)
    }

    func test_wellbeingBreakdownContract_weakDimensionsAllBelowNeutralThreshold() {
        self.sut.meals = [MealBuilder().build()]
        guard let contract = self.sut.wellbeingBreakdownContract else { return }
        for dim in contract.weakDimensions {
            let value = dim.value(in: contract.dimensions)
            XCTAssertLessThan(
                value,
                SynthesisThresholds.overallNeutral,
                "\(dim.displayName) (\(value)) should be below neutral threshold"
            )
        }
    }

    // MARK: - Data Isolation (Structural)

    func test_wellbeingBreakdownSheetContract_isValueType() {
        // Contract must be a struct (value type) — no MainViewModel reference
        XCTAssertTrue(
            Mirror(reflecting: WellbeingBreakdownSheetContract(
                dimensions: .neutral,
                dominantDimension: .physicalLoad,
                causalNarrative: "test",
                weakDimensions: [],
                mealCount: 0
            )).displayStyle == .struct
        )
    }

    func test_wellbeingBreakdownSheetContract_equatable() {
        let a = WellbeingBreakdownSheetContract(
            dimensions: .neutral,
            dominantDimension: .physicalLoad,
            causalNarrative: "test",
            weakDimensions: [.emotionalTone],
            mealCount: 2
        )
        let b = WellbeingBreakdownSheetContract(
            dimensions: .neutral,
            dominantDimension: .physicalLoad,
            causalNarrative: "test",
            weakDimensions: [.emotionalTone],
            mealCount: 2
        )
        XCTAssertEqual(a, b)
    }

    // MARK: - Breakdown Sheet Toggle

    func test_handleSmileyLongPress_withBreakdownContract_opensBreakdownSheet() {
        self.sut.meals = [MealBuilder().build()]
        self.sut.handleSmileyLongPress()
        XCTAssertTrue(self.sut.showBreakdownSheet)
        XCTAssertFalse(self.sut.showInsightSheet)
    }

    func test_handleSmileyLongPress_noDataNoSheets() {
        // No meals → no breakdown contract; no insight → no insight sheet
        self.sut.handleSmileyLongPress()
        XCTAssertFalse(self.sut.showBreakdownSheet)
        XCTAssertFalse(self.sut.showInsightSheet)
    }
}
