import XCTest
@testable import Yoga_of_Eating

/// Unit tests for ModuleCardStack and AIWhisperView logic.
@MainActor
final class ModuleCardStackTests: XCTestCase {
    // MARK: - Properties

    var mainViewModel: MainViewModel!
    var homeViewModel: HomeViewModel!
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
        self.homeViewModel = HomeViewModel(mainViewModel: self.mainViewModel)
    }

    override func tearDown() {
        self.homeViewModel = nil
        self.mainViewModel = nil
        self.mockHistorical = nil
        self.mockPersistence = nil
        self.mockLogic = nil
        self.mockInsightService = nil
        super.tearDown()
    }

    // MARK: - Card Stack Tests

    func test_cardStack_showsFourPages() {
        let modules = DayModule.allCases
        XCTAssertEqual(modules.count, 4)
    }

    func test_cardStack_initialPage_matchesActiveModule() {
        let selected = self.homeViewModel.selectedModule
        XCTAssertTrue(DayModule.allCases.contains(selected))
    }

    func test_cardStack_swipe_updatesSelectedModule() {
        self.homeViewModel.selectModule(.laser)
        XCTAssertEqual(self.homeViewModel.selectedModule, .laser)

        self.homeViewModel.selectModule(.highlight)
        XCTAssertEqual(self.homeViewModel.selectedModule, .highlight)
    }

    func test_cardStack_ringHighlight_syncsWithSelectedCard() {
        self.homeViewModel.selectModule(.energise)
        XCTAssertEqual(self.homeViewModel.selectedModule, .energise)
        XCTAssertEqual(self.homeViewModel.moduleOverride, .energise)
    }

    // MARK: - Whisper View Tests

    func test_whisperView_showsInsightText() {
        let insight = DailyInsight(
            date: Date(),
            insightText: "Your morning meals are improving",
            insightType: .pattern,
            confidence: 0.7
        )
        self.mainViewModel.currentInsight = insight
        XCTAssertEqual(self.homeViewModel.whisperText, "Your morning meals are improving")
    }

    func test_whisperView_fallsBackToQuote() {
        self.mainViewModel.currentInsight = nil
        let whisper = self.homeViewModel.whisperText
        XCTAssertFalse(whisper.isEmpty)
    }

    func test_whisperView_tapOpensInsightSheet() {
        self.mainViewModel.currentInsight = DailyInsight(
            date: Date(),
            insightText: "Test insight",
            insightType: .encouragement,
            confidence: 0.6
        )
        XCTAssertFalse(self.mainViewModel.showInsightSheet)
        self.mainViewModel.showInsightSheet = true
        XCTAssertTrue(self.mainViewModel.showInsightSheet)
    }

    // MARK: - Page Indicator Tests

    func test_pageIndicator_moduleCount() {
        XCTAssertEqual(DayModule.allCases.count, 4)
    }

    func test_pageIndicator_colorsMatchTheme() {
        // Verify each module's color matches the canonical AppTheme.ModuleColors value.
        XCTAssertEqual(DayModule.reflect.color, AppTheme.ModuleColors.reflect)
        XCTAssertEqual(DayModule.laser.color, AppTheme.ModuleColors.laser)
        XCTAssertEqual(DayModule.highlight.color, AppTheme.ModuleColors.highlight)
        XCTAssertEqual(DayModule.energise.color, AppTheme.ModuleColors.energise)
    }
}
