import XCTest
@testable import Yoga_of_Eating

/// Unit tests for Phase 1 foundation: DayPhase, DayModule, ActiveModuleResolver, HomeViewModel.
@MainActor
final class HomeViewModelTests: XCTestCase {
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

    // MARK: - DayPhase Tests

    func test_dayPhase_morning_beforeNoon() {
        XCTAssertEqual(DayPhase.current(at: 7), .morning)
        XCTAssertEqual(DayPhase.current(at: 0), .morning)
        XCTAssertEqual(DayPhase.current(at: 11), .morning)
    }

    func test_dayPhase_midday_noonToFive() {
        XCTAssertEqual(DayPhase.current(at: 12), .midday)
        XCTAssertEqual(DayPhase.current(at: 14), .midday)
        XCTAssertEqual(DayPhase.current(at: 16), .midday)
    }

    func test_dayPhase_evening_afterFive() {
        XCTAssertEqual(DayPhase.current(at: 17), .evening)
        XCTAssertEqual(DayPhase.current(at: 20), .evening)
        XCTAssertEqual(DayPhase.current(at: 23), .evening)
    }

    // MARK: - DayModule Tests

    func test_allModules_orderedCorrectly() {
        let modules = DayModule.allCases
        XCTAssertEqual(modules.count, 4)
        XCTAssertEqual(modules[0], .reflect)
        XCTAssertEqual(modules[1], .laser)
        XCTAssertEqual(modules[2], .highlight)
        XCTAssertEqual(modules[3], .energise)
    }

    func test_dayModule_titlesUseStringResources() {
        XCTAssertEqual(DayModule.reflect.title, Strings.DayRing.reflect)
        XCTAssertEqual(DayModule.laser.title, Strings.DayRing.laser)
        XCTAssertEqual(DayModule.highlight.title, Strings.DayRing.highlight)
        XCTAssertEqual(DayModule.energise.title, Strings.DayRing.energise)
    }

    // MARK: - ActiveModuleResolver Tests

    func test_activeModule_morning_noData_returnsReflect() {
        let result = ActiveModuleResolver.resolve(
            phase: .morning,
            hasIntention: false,
            override: nil
        )
        XCTAssertEqual(result, .reflect)
    }

    func test_activeModule_morning_hasIntention_returnsEnergise() {
        let result = ActiveModuleResolver.resolve(
            phase: .morning,
            hasIntention: true,
            override: nil
        )
        XCTAssertEqual(result, .energise)
    }

    func test_activeModule_midday_returnsEnergise() {
        let result = ActiveModuleResolver.resolve(
            phase: .midday,
            hasIntention: false,
            override: nil
        )
        XCTAssertEqual(result, .energise)
    }

    func test_activeModule_evening_returnsHighlight() {
        let result = ActiveModuleResolver.resolve(
            phase: .evening,
            hasIntention: false,
            override: nil
        )
        XCTAssertEqual(result, .highlight)
    }

    func test_activeModule_respectsOverride() {
        let result = ActiveModuleResolver.resolve(
            phase: .morning,
            hasIntention: false,
            override: .laser
        )
        XCTAssertEqual(result, .laser)
    }

    func test_homeViewModel_isReadyBeforeOnAppear() {
        // Verify HomeViewModel computes a valid selectedModule immediately after init,
        // with no onAppear or bind() needed — fixing the A2 stale first-render bug.
        let vm = HomeViewModel(mainViewModel: self.mainViewModel)
        let module = vm.selectedModule
        XCTAssertTrue(DayModule.allCases.contains(module))
        XCTAssertFalse(vm.avatarEmoji.isEmpty)
        XCTAssertFalse(vm.whisperText.isEmpty)
    }

    // MARK: - HomeViewModel Tests

    func test_homeViewModel_avatarEmoji_noMeals_neutral() {
        let vm = HomeViewModel(mainViewModel: self.mainViewModel)
        XCTAssertEqual(vm.avatarEmoji, Strings.Home.avatarNeutral)
    }

    func test_homeViewModel_avatarEmoji_goodScore_serene() {
        self.mainViewModel.meals = [
            Meal(items: ["Salad"], healthScore: 0.85, isAIAnalyzed: true)
        ]
        let vm = HomeViewModel(mainViewModel: self.mainViewModel)
        XCTAssertEqual(vm.avatarEmoji, Strings.Home.avatarSerene)
    }

    func test_homeViewModel_avatarEmoji_lowScore_overwhelmed() {
        self.mainViewModel.meals = [
            Meal(items: ["Pizza", "Fries"], healthScore: 0.25, isAIAnalyzed: true)
        ]
        let vm = HomeViewModel(mainViewModel: self.mainViewModel)
        XCTAssertEqual(vm.avatarEmoji, Strings.Home.avatarOverwhelmed)
    }

    func test_homeViewModel_whisperText_hasInsight_returnsInsightText() {
        let insight = DailyInsight(
            date: Date(),
            insightText: "Light meals boost your afternoon energy",
            insightType: .foodSleep,
            confidence: 0.8
        )
        self.mainViewModel.currentInsight = insight
        let vm = HomeViewModel(mainViewModel: self.mainViewModel)
        XCTAssertEqual(vm.whisperText, "Light meals boost your afternoon energy")
    }

    func test_homeViewModel_whisperText_noInsight_returnsDailyQuote() {
        self.mainViewModel.currentInsight = nil
        let vm = HomeViewModel(mainViewModel: self.mainViewModel)
        XCTAssertFalse(vm.whisperText.isEmpty)
    }

    func test_homeViewModel_selectModule_setsOverride() {
        let vm = HomeViewModel(mainViewModel: self.mainViewModel)
        vm.selectModule(.laser)
        XCTAssertEqual(vm.moduleOverride, .laser)
        XCTAssertEqual(vm.selectedModule, .laser)
    }

    func test_homeViewModel_resetToAutoModule_clearsOverride() {
        let vm = HomeViewModel(mainViewModel: self.mainViewModel)
        vm.selectModule(.laser)
        vm.resetToAutoModule()
        XCTAssertNil(vm.moduleOverride)
    }
}
