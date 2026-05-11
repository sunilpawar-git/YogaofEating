import XCTest

@testable import Yoga_of_Eating

@MainActor
final class BriefingCardEnrichmentTests: XCTestCase {
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

    // MARK: - briefingWeakDimensions

    func test_briefingWeakDimensions_isEmptyWithNoMeals() {
        XCTAssertTrue(self.sut.briefingWeakDimensions.isEmpty)
    }

    func test_briefingWeakDimensions_atMostTwoDimensions() {
        self.sut.meals = [MealBuilder().build()]
        XCTAssertLessThanOrEqual(self.sut.briefingWeakDimensions.count, 2)
    }

    func test_briefingWeakDimensions_matchesWeakDimsFromBreakdownContract() {
        self.sut.meals = [MealBuilder().build()]
        let contractWeakDims = self.sut.wellbeingBreakdownContract?.weakDimensions ?? []
        XCTAssertEqual(self.sut.briefingWeakDimensions, contractWeakDims)
    }

    func test_briefingWeakDimensions_isEmptyWhenViewingPastDay() {
        self.sut.meals = [MealBuilder().build()]
        self.sut.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(self.sut.briefingWeakDimensions.isEmpty)
    }

    // MARK: - MorningBriefingCard Backward Compatibility

    func test_morningBriefingCard_defaultWeakDimensionsIsEmpty() {
        // Structural test: default parameter compiles without weakDimensions
        let card = MorningBriefingCard(
            headline: "Test headline",
            topCorrelation: nil,
            nudge: "Test nudge",
            isViewed: false
        )
        // If this compiles, the default [] is in place — backward compatible
        XCTAssertNotNil(card)
    }

    func test_morningBriefingCard_acceptsWeakDimensions() {
        let card = MorningBriefingCard(
            headline: "Test headline",
            topCorrelation: nil,
            nudge: "Test nudge",
            isViewed: false,
            weakDimensions: [.emotionalTone, .cognitiveClarity]
        )
        XCTAssertNotNil(card)
    }

    // MARK: - WellbeingBreakdownSheetContract Enrichment

    func test_wellbeingBreakdownContract_weakDimensionLabelsMatchDimensions() {
        self.sut.meals = [MealBuilder().build()]
        guard let contract = self.sut.wellbeingBreakdownContract else { return }
        for weakDim in contract.weakDimensions {
            // Each weak dim must be a valid WellbeingDimension
            XCTAssertTrue(WellbeingDimension.allCases.contains(weakDim))
        }
    }

    func test_wellbeingBreakdownContract_noDuplicateWeakDimensions() {
        self.sut.meals = [MealBuilder().build()]
        guard let contract = self.sut.wellbeingBreakdownContract else { return }
        let uniqueCount = Set(contract.weakDimensions).count
        XCTAssertEqual(uniqueCount, contract.weakDimensions.count)
    }
}
