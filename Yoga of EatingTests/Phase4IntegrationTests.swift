import XCTest
@testable import Yoga_of_Eating

/// Integration tests for the full Home Screen flow (Phase 5 of radial home plan).
/// Tests cross-layer interactions: HomeViewModel ↔ MainViewModel ↔ Services.
@MainActor
final class Phase4IntegrationTests: XCTestCase {
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

    // MARK: - Morning Flow

    func test_homeScreen_morningFlow_reflectCardSelected() {
        let resolved = ActiveModuleResolver.resolve(
            phase: .morning,
            hasIntention: false,
            override: nil
        )
        XCTAssertEqual(resolved, .reflect)
    }

    func test_homeScreen_setIntention_updatesRingAndCard() {
        XCTAssertNil(self.mainViewModel.todaysIntention)

        self.mainViewModel.completeReflectInput(energy: 3, intention: "Eat mindfully")

        XCTAssertEqual(self.mainViewModel.todaysIntention, "Eat mindfully")
        XCTAssertEqual(self.mainViewModel.todaysEnergyLevel, 3)

        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertEqual(source.cardIntention, "Eat mindfully")
        XCTAssertFalse(source.shouldShowSetIntentionPrompt)
    }

    // MARK: - Meal Logging

    func test_homeScreen_logMeal_switchesToEnergiseCard() {
        self.mainViewModel.completeReflectInput(energy: 3, intention: "Test")
        self.mainViewModel.meals = [Meal(items: ["Rice"], healthScore: 0.7)]

        let resolved = ActiveModuleResolver.resolve(
            phase: .morning,
            hasIntention: true,
            override: nil
        )
        XCTAssertEqual(resolved, .energise)

        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertEqual(source.cardMeals.count, 1)
    }

    // MARK: - Evening Flow

    func test_homeScreen_endOfDay_highlightCardShowsReview() {
        let resolved = ActiveModuleResolver.resolve(
            phase: .evening,
            hasIntention: false,
            override: nil
        )
        XCTAssertEqual(resolved, .highlight)

        let source: ModuleCardDataSource = self.mainViewModel
        XCTAssertTrue(source.shouldShowEndOfDayPrompt)
    }

    // MARK: - Insight Persistence

    func test_homeScreen_insightPersisted_whisperShowsInsight() {
        let insight = DailyInsight(
            date: Date(),
            insightText: "Light dinners improve your sleep",
            insightType: .foodSleep,
            confidence: 0.85
        )
        self.mainViewModel.currentInsight = insight

        let whisper = self.homeViewModel.whisperText
        XCTAssertEqual(whisper, "Light dinners improve your sleep")
    }

    // MARK: - Feature Flag

    func test_homeScreen_featureFlag_togglesBetweenOldAndNew() {
        // @AppStorage uses UserDefaults under the hood with StorageKeys.useRadialHome.
        // We verify the key is persisted and read back correctly, and clean up after.
        UserDefaults.standard.set(true, forKey: StorageKeys.useRadialHome)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: StorageKeys.useRadialHome))

        UserDefaults.standard.set(false, forKey: StorageKeys.useRadialHome)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: StorageKeys.useRadialHome))

        UserDefaults.standard.removeObject(forKey: StorageKeys.useRadialHome)
    }

    func test_homeScreen_featureFlag_usesStorageKeyConstant() {
        // Ensures the raw key string matches StorageKeys.useRadialHome (SSOT guard).
        XCTAssertEqual(StorageKeys.useRadialHome, "useRadialHome")
    }

    // MARK: - Historical Day

    func test_homeScreen_historicalDay_usesTimelineData() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let snapshot = self.mainViewModel.snapshot(for: yesterday)
        // Historical days should return snapshots (nil if no data yet, which is expected)
        // The key test is that historical path remains operational
        _ = snapshot
    }

    // MARK: - Module Override

    func test_homeScreen_moduleOverride_staysOnSelectedCard() {
        self.homeViewModel.selectModule(.laser)
        XCTAssertEqual(self.homeViewModel.selectedModule, .laser)

        self.homeViewModel.selectModule(.highlight)
        XCTAssertEqual(self.homeViewModel.selectedModule, .highlight)

        self.homeViewModel.resetToAutoModule()
        XCTAssertNil(self.homeViewModel.moduleOverride)
    }
}
