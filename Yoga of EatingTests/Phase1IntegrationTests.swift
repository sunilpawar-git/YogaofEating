import XCTest
@testable import Yoga_of_Eating

/// Integration tests verifying Phase 1 cross-layer flows:
/// Reflect → Energise → Laser → Highlight pipeline.
@MainActor
final class Phase1IntegrationTests: XCTestCase {
    // MARK: - Properties

    var viewModel: MainViewModel!
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
        self.viewModel = MainViewModel(
            logicService: self.mockLogic,
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            insightService: self.mockInsightService
        )
    }

    override func tearDown() {
        self.viewModel = nil
        self.mockHistorical = nil
        self.mockPersistence = nil
        self.mockLogic = nil
        self.mockInsightService = nil
        super.tearDown()
    }

    // MARK: - Reflect → ViewModel → HistoricalData

    func test_reflectFlow_endToEnd_persistsEnergyAndIntention() {
        // Given: User completes sleep
        self.viewModel.saveSleepQuality(.good)

        // When: User completes reflect input
        self.viewModel.completeReflectInput(energy: 4, intention: "Eat mindfully today")

        // Then: Reflection is stored with all fields
        let snapshot = self.mockHistorical.historicalData.snapshot(for: Date())
        let reflection = snapshot?.reflection
        XCTAssertNotNil(reflection)
        XCTAssertEqual(reflection?.sleepQuality, .good)
        XCTAssertEqual(reflection?.morningEnergyLevel, 4)
        XCTAssertEqual(reflection?.dailyIntention, "Eat mindfully today")
    }

    func test_reflectFlow_showsSheetAfterSleep_whenNoIntention() {
        // When: User completes sleep quality input
        self.viewModel.completeSleepQualityInput(.good)

        // Then: Reflect sheet is shown
        XCTAssertTrue(self.viewModel.showReflectSheet)
    }

    func test_reflectFlow_doesNotShowSheet_whenIntentionAlreadySet() {
        // Given: Intention already set
        self.viewModel.completeReflectInput(energy: 3, intention: "Eat light")

        // When: User completes sleep quality input again
        self.viewModel.completeSleepQualityInput(.great)

        // Then: Reflect sheet should NOT show (intention already exists)
        XCTAssertFalse(self.viewModel.showReflectSheet)
    }

    // MARK: - Intent Alignment Service (Laser layer)

    func test_intentAlignment_detects_positiveAlignment() {
        let hint = IntentAlignmentService.alignmentHint(
            intention: "Eat lighter today",
            mealItems: ["Salad", "Fruit bowl"]
        )
        XCTAssertNotNil(hint)
        XCTAssertFalse(hint?.contains("nudge") ?? true, "Light meals should show positive alignment")
    }

    func test_intentAlignment_detects_misalignment() {
        let hint = IntentAlignmentService.alignmentHint(
            intention: "No sugar today",
            mealItems: ["Ice cream", "Chocolate cake"]
        )
        XCTAssertNotNil(hint)
        XCTAssertTrue(hint?.contains("nudge") ?? false, "Sugary items should trigger a nudge")
    }

    func test_intentAlignment_returnsNil_forUnrelatedIntention() {
        let hint = IntentAlignmentService.alignmentHint(
            intention: "Be productive",
            mealItems: ["Rice", "Chicken"]
        )
        XCTAssertNil(hint, "Non-food intentions should not trigger alignment hints")
    }

    // MARK: - Insight Persistence (Highlight layer)

    func test_insightPersistence_roundTrips_throughSnapshot() {
        let insight = DailyInsight(
            date: Date(),
            insightText: "Great pattern detected!",
            insightType: .intentAlignment,
            confidence: 0.85
        )

        // When: Save insight
        self.mockHistorical.updateDailyInsight(for: Date(), insight: insight)

        // Then: Retrieve from snapshot
        let snapshot = self.mockHistorical.historicalData.snapshot(for: Date())
        XCTAssertNotNil(snapshot?.dailyInsight)
        XCTAssertEqual(snapshot?.dailyInsight?.insightText, "Great pattern detected!")
        XCTAssertEqual(snapshot?.dailyInsight?.insightType, .intentAlignment)
    }

    func test_insightType_intentAlignment_hasCorrectProperties() {
        XCTAssertEqual(InsightType.intentAlignment.rawValue, "intentAlignment")
        XCTAssertEqual(InsightType.intentAlignment.icon, "target")
        XCTAssertEqual(InsightType.intentAlignment.displayName, "Intent Alignment")
    }

    // MARK: - ViewModel Insight Restore (loadData)

    func test_loadData_restoresInsight_fromSnapshot() {
        // Given: A snapshot with an insight
        let insight = DailyInsight(
            date: Date(),
            insightText: "You ate well today!",
            insightType: .encouragement,
            confidence: 0.7
        )
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.5,
            dailyInsight: insight
        )
        self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)

        // Simulate persisted state
        self.mockPersistence.savedData = PersistenceService.AppData(
            meals: [],
            smileyState: .neutral,
            lastResetDate: Date(),
            historicalData: self.mockHistorical.historicalData
        )

        // When: Load data
        self.viewModel.loadData()

        // Then: Current insight is restored
        XCTAssertNotNil(self.viewModel.currentInsight)
        XCTAssertEqual(self.viewModel.currentInsight?.insightText, "You ate well today!")
    }

    // MARK: - DailyReflection Backward Compatibility

    func test_dailyReflection_backwardCompatibility_decodesWithoutNewFields() throws {
        let json = """
        {
            "sleepQuality": "good",
            "feeling": "great",
            "timestamp": 1000000
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let reflection = try decoder.decode(DailyReflection.self, from: data)

        XCTAssertEqual(reflection.sleepQuality, .good)
        XCTAssertNil(reflection.morningEnergyLevel, "Legacy data should have nil energy")
        XCTAssertNil(reflection.dailyIntention, "Legacy data should have nil intention")
    }

    // MARK: - DailySmileySnapshot Backward Compatibility

    func test_dailySmileySnapshot_backwardCompatibility_decodesWithoutInsight() throws {
        let json = """
        {
            "id": "12345678-1234-1234-1234-123456789ABC",
            "date": 1000000,
            "smileyState": {"scale": 1.0, "mood": "neutral"},
            "meals": [],
            "mealCount": 0,
            "averageHealthScore": 0.5
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let snapshot = try decoder.decode(DailySmileySnapshot.self, from: data)

        XCTAssertNil(snapshot.dailyInsight, "Legacy data should have nil dailyInsight")
    }

    // MARK: - AI Protocol Intention Parameter

    func test_todaysIntention_reflectsCurrentReflection() {
        // Given: No reflection yet
        XCTAssertNil(self.viewModel.todaysIntention)

        // When: Set intention via reflect
        self.viewModel.completeReflectInput(energy: 3, intention: "Less sugar")

        // Then: todaysIntention reflects it
        XCTAssertEqual(self.viewModel.todaysIntention, "Less sugar")
    }
}
