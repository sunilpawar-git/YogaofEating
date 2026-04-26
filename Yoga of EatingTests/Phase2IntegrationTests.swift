import XCTest
@testable import Yoga_of_Eating

/// Integration tests validating cross-layer behavior for Phase 2 features:
/// DayModuleProgress, focusRating, TodoAnalytics, observation, focusFood InsightType.
@MainActor
final class Phase2IntegrationTests: XCTestCase {
    var mockHistorical: MockHistoricalDataService!
    var mockPersistence: MockPersistenceService!
    var mockLogic: MockMealLogicService!
    var viewModel: MainViewModel!

    override func setUp() {
        super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        self.mockPersistence = MockPersistenceService()
        self.mockLogic = MockMealLogicService()
        self.viewModel = MainViewModel(
            logicService: self.mockLogic,
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical
        )
    }

    override func tearDown() {
        self.viewModel = nil
        self.mockHistorical = nil
        self.mockPersistence = nil
        self.mockLogic = nil
        super.tearDown()
    }

    // MARK: - Full Day Flow

    func test_fullDayFlow_allModulesReach100() {
        self.viewModel.completeSleepQualityInput(.great)
        self.viewModel.completeReflectInput(energy: 5, intention: "Eat clean")
        self.viewModel.saveFocusRating(3)

        let meal = Meal(mealType: .lunch, items: ["Salad"], healthScore: 0.9)
        let todo = MindCheckEntry(
            category: .todo, text: "Walk", context: .morning, isAccomplished: true
        )
        let gratitude = MindCheckEntry(
            category: .gratefulFor, text: "Sun", context: .evening
        )
        let observation = MindCheckEntry(
            category: .observation, text: "Felt lighter", context: .evening
        )

        let snapshot = DailySmileySnapshot.create(
            date: Date(),
            smileyState: .neutral,
            meals: [meal],
            reflection: DailyReflection(
                feeling: .great,
                sleepQuality: .great,
                morningEnergyLevel: 5,
                dailyIntention: "Eat clean",
                focusRating: 3
            ),
            morningMindCheck: [todo],
            eveningMindCheck: [gratitude, observation]
        )

        let progress = DayModuleProgress.compute(from: snapshot)
        XCTAssertEqual(progress.reflectProgress, 1.0, accuracy: 0.01)
        XCTAssertEqual(progress.laserProgress, 1.0, accuracy: 0.01)
        XCTAssertEqual(progress.highlightProgress, 1.0, accuracy: 0.01)
        XCTAssertEqual(progress.energiseProgress, 1.0, accuracy: 0.01)
        XCTAssertEqual(progress.overallProgress, 1.0, accuracy: 0.01)
    }

    // MARK: - Focus Rating -> Laser Module

    func test_focusRating_increasesLaserProgress() {
        let withoutFocus = DailySmileySnapshot.create(
            date: Date(), smileyState: .neutral,
            meals: [Meal(mealType: .lunch, items: ["Rice"], healthScore: 0.5)]
        )
        let withFocus = DailySmileySnapshot.create(
            date: Date(), smileyState: .neutral,
            meals: [Meal(mealType: .lunch, items: ["Rice"], healthScore: 0.5)],
            reflection: DailyReflection(focusRating: 2)
        )

        let progressWithout = DayModuleProgress.compute(from: withoutFocus)
        let progressWith = DayModuleProgress.compute(from: withFocus)

        XCTAssertGreaterThan(progressWith.laserProgress, progressWithout.laserProgress)
    }

    // MARK: - Observation -> Highlight Module

    func test_observation_increasesHighlightProgress() {
        let withoutObs = DailySmileySnapshot.create(
            date: Date(), smileyState: .neutral, meals: [],
            reflection: DailyReflection(feeling: .calm),
            eveningMindCheck: [
                MindCheckEntry(category: .gratefulFor, text: "Sun", context: .evening)
            ]
        )
        let withObs = DailySmileySnapshot.create(
            date: Date(), smileyState: .neutral, meals: [],
            reflection: DailyReflection(feeling: .calm),
            eveningMindCheck: [
                MindCheckEntry(category: .gratefulFor, text: "Sun", context: .evening),
                MindCheckEntry(category: .observation, text: "Less hungry", context: .evening)
            ]
        )

        let progressWithout = DayModuleProgress.compute(from: withoutObs)
        let progressWith = DayModuleProgress.compute(from: withObs)

        XCTAssertGreaterThan(progressWith.highlightProgress, progressWithout.highlightProgress)
    }

    // MARK: - TodoAnalytics from ViewModel Data

    func test_todoAnalytics_computesFromSnapshots() {
        let cal = Calendar.current
        let today = Date()

        for daysAgo in 0..<3 {
            let date = cal.date(byAdding: .day, value: -daysAgo, to: today)!
            let todo = MindCheckEntry(
                category: .todo, text: "Task \(daysAgo)",
                context: .morning, isAccomplished: daysAgo < 2
            )
            let snapshot = DailySmileySnapshot.create(
                date: date, smileyState: .neutral, meals: [],
                morningMindCheck: [todo]
            )
            self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)
        }

        let snapshots = self.mockHistorical.historicalData.dailySnapshots
        let analytics = TodoAnalyticsService.compute(from: snapshots)

        XCTAssertEqual(analytics.totalCreated, 3)
        XCTAssertEqual(analytics.totalCompleted, 2)
        XCTAssertGreaterThan(analytics.completionRate, 0.5)
    }

    // MARK: - FocusFood InsightType

    func test_focusFood_insightType_properties() {
        XCTAssertEqual(InsightType.focusFood.rawValue, "focusFood")
        XCTAssertEqual(InsightType.focusFood.icon, "bolt.circle")
        XCTAssertEqual(InsightType.focusFood.displayName, "Focus & Food")
    }

    func test_focusFood_insight_encodesAndDecodes() throws {
        let insight = DailyInsight(
            date: Date(),
            insightText: "Lighter lunch improved your afternoon focus.",
            insightType: .focusFood,
            confidence: 0.85
        )
        let data = try JSONEncoder().encode(insight)
        let decoded = try JSONDecoder().decode(DailyInsight.self, from: data)

        XCTAssertEqual(decoded.insightType, .focusFood)
        XCTAssertEqual(decoded.insightText, insight.insightText)
    }

    // MARK: - Backward Compatibility

    func test_focusRating_backwardCompatible_snapshotWithout() throws {
        let snapshot = DailySmileySnapshot.create(
            date: Date(), smileyState: .neutral, meals: [],
            reflection: DailyReflection(sleepQuality: .good)
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(DailySmileySnapshot.self, from: data)

        XCTAssertNil(decoded.reflection?.focusRating)
        XCTAssertEqual(decoded.reflection?.sleepQuality, .good)
    }

    func test_observation_backwardCompatible_snapshotWithout() throws {
        let snapshot = DailySmileySnapshot.create(
            date: Date(), smileyState: .neutral, meals: [],
            eveningMindCheck: [
                MindCheckEntry(category: .gratefulFor, text: "Weather", context: .evening)
            ]
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(DailySmileySnapshot.self, from: data)

        XCTAssertFalse(
            decoded.eveningMindCheck?.contains { $0.category == .observation } ?? false
        )
    }

    // MARK: - DayModuleProgress Clamping

    func test_moduleProgress_neverExceedsOne() {
        let reflection = DailyReflection(
            feeling: .great,
            sleepQuality: .great,
            morningEnergyLevel: 5,
            dailyIntention: "Test",
            focusRating: 3
        )
        let meal = Meal(mealType: .lunch, items: ["A"], healthScore: 1.0)
        let snapshot = DailySmileySnapshot.create(
            date: Date(), smileyState: .neutral,
            meals: [meal],
            reflection: reflection,
            morningMindCheck: [
                MindCheckEntry(
                    category: .todo, text: "T",
                    context: .morning, isAccomplished: true
                )
            ],
            eveningMindCheck: [
                MindCheckEntry(category: .gratefulFor, text: "G", context: .evening),
                MindCheckEntry(category: .observation, text: "O", context: .evening)
            ]
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertLessThanOrEqual(progress.reflectProgress, 1.0)
        XCTAssertLessThanOrEqual(progress.laserProgress, 1.0)
        XCTAssertLessThanOrEqual(progress.highlightProgress, 1.0)
        XCTAssertLessThanOrEqual(progress.energiseProgress, 1.0)
        XCTAssertLessThanOrEqual(progress.overallProgress, 1.0)
    }

    // MARK: - ViewModel Focus Save + Read

    func test_viewModel_saveFocusRating_roundTrip() {
        self.viewModel.saveFocusRating(2)

        let snapshot = self.mockHistorical.historicalData.snapshot(for: Date())
        XCTAssertEqual(snapshot?.reflection?.focusRating, 2)
        XCTAssertEqual(self.viewModel.todaysFocusRating, 2)
    }
}
