import XCTest
@testable import Yoga_of_Eating

/// Unit tests for module card data source protocol and card body logic.
@MainActor
final class ModuleCardTests: XCTestCase {
    // MARK: - Properties

    var mainViewModel: MainViewModel!
    var mockHistorical: MockHistoricalDataService!
    var mockPersistence: MockPersistenceService!
    var mockLogic: MockMealLogicService!
    var mockInsightService: MockInsightGenerationService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        self.mockPersistence = MockPersistenceService()
        self.mockLogic = MockMealLogicService()
        self.mockInsightService = MockInsightGenerationService(historicalService: self.mockHistorical)
        self.mainViewModel = MainViewModel(
            logicService: self.mockLogic,
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            insightService: self.mockInsightService
        )
    }

    override func tearDown() {
        self.mainViewModel = nil
        self.mockHistorical = nil
        self.mockPersistence = nil
        self.mockLogic = nil
        self.mockInsightService = nil
        super.tearDown()
    }

    // MARK: - Reflect Card Data

    func test_reflectCard_noIntention_showsSetIntentionButton() {
        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertNil(source.cardIntention)
        XCTAssertTrue(source.shouldShowSetIntentionPrompt)
    }

    func test_reflectCard_hasIntention_showsIntentionText() {
        self.mainViewModel.completeReflectInput(energy: 3, intention: "Eat slowly today")
        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertEqual(source.cardIntention, "Eat slowly today")
        XCTAssertFalse(source.shouldShowSetIntentionPrompt)
    }

    func test_reflectCard_hasEnergy_showsEnergyLevel() {
        self.mainViewModel.completeReflectInput(energy: 4, intention: "Test")
        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertEqual(source.cardEnergyLevel, 4)
    }

    func test_reflectCard_hasSleep_showsSleepQuality() {
        self.mainViewModel.saveSleepQuality(.good)
        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertEqual(source.cardSleepQuality, .good)
    }

    // MARK: - Energise Card Data

    func test_energiseCard_noMeals_showsLogMealButton() {
        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertTrue(source.cardMeals.isEmpty)
        XCTAssertTrue(source.shouldShowLogMealPrompt)
    }

    func test_energiseCard_hasMeals_showsMealSummary() {
        self.mainViewModel.meals = [
            Meal(items: ["Salad"], healthScore: 0.8)
        ]
        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertEqual(source.cardMeals.count, 1)
        XCTAssertFalse(source.shouldShowLogMealPrompt)
    }

    // MARK: - Laser Card Data

    func test_laserCard_noTodos_showsEmptyState() {
        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertTrue(source.cardMorningTodos.isEmpty)
    }

    func test_laserCard_showsFocusRating() {
        self.mainViewModel.saveFocusRating(2)
        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertEqual(source.cardFocusRating, 2)
    }

    // MARK: - Highlight Card Data

    func test_highlightCard_noFeeling_showsEndOfDayButton() {
        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertNil(source.cardFeeling)
        XCTAssertTrue(source.shouldShowEndOfDayPrompt)
    }

    func test_highlightCard_hasFeeling_showsFeelingBadge() {
        let reflection = DailyReflection(feeling: .great, timestamp: Date())
        self.mainViewModel.saveReflection(reflection)
        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertEqual(source.cardFeeling, .great)
    }

    func test_highlightCard_hasInsight_showsInsightText() {
        let insight = DailyInsight(
            date: Date(),
            insightText: "Great meal choices today",
            insightType: .foodSleep,
            confidence: 0.9
        )
        self.mainViewModel.currentInsight = insight
        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertEqual(source.cardInsightText, "Great meal choices today")
    }

    func test_highlightCard_planVsExecution_formatted() {
        self.mainViewModel.completeReflectInput(energy: 3, intention: "Eat light")
        self.mainViewModel.meals = [
            Meal(items: ["Soup"], healthScore: 0.9, isAIAnalyzed: true)
        ]
        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertNotNil(source.cardIntention)
        XCTAssertFalse(source.cardMeals.isEmpty)
    }
}
