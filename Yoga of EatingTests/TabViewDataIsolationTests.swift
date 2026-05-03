import XCTest
@testable import Yoga_of_Eating

/// Unit tests verifying that tab views receive only minimal required data
/// and cannot access sensitive user information.
@MainActor
final class TabViewDataIsolationTests: XCTestCase {
    var viewModel: MainViewModel!
    var mockHistorical: MockHistoricalDataService!

    override func setUp() {
        super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        self.viewModel = MainViewModel(
            historicalService: self.mockHistorical,
            skipDataLoading: true
        )
    }

    // MARK: - HighlightViewContract Data Isolation Tests

    func test_highlightViewData_defaultsToEmpty() {
        let data = self.viewModel.highlightViewData
        XCTAssertNil(data.sleepQuality)
        XCTAssertNil(data.sleepNotes)
        XCTAssertTrue(data.todos.isEmpty)
        XCTAssertNil(data.morningThoughts)
        XCTAssertTrue(data.isToday)
    }

    func test_highlightViewData_reflectsSavedHighlightData() {
        let highlight = HighlightData(
            sleepQuality: .good,
            sleepNotes: "Slept well",
            todos: [MindCheckEntry(category: .todo, text: "Buy eggs", context: .morning)],
            morningThoughts: "Feeling rested"
        )
        self.mockHistorical.updateHighlightData(for: Date(), data: highlight)

        let data = self.viewModel.highlightViewData
        XCTAssertEqual(data.sleepQuality, .good)
        XCTAssertEqual(data.sleepNotes, "Slept well")
        XCTAssertEqual(data.todos.count, 1)
        XCTAssertEqual(data.morningThoughts, "Feeling rested")
    }

    func test_highlightViewData_cannotAccessMeals() {
        self.viewModel.meals = [
            Meal(
                id: UUID(),
                timestamp: Date(),
                mealType: .breakfast,
                items: ["Medication", "Private health supplement"],
                healthScore: 0.5,
                isAIAnalyzed: false
            )
        ]

        let data = self.viewModel.highlightViewData
        XCTAssertTrue(data.isToday)
    }

    func test_highlightViewData_cannotAccessSmileyState() {
        self.viewModel.smileyState = SmileyState(scale: 2.0, mood: .serene)
        let data = self.viewModel.highlightViewData
        XCTAssertTrue(data.isToday)
    }

    func test_highlightViewData_showsHistoricalData() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let highlight = HighlightData(sleepQuality: .poor, morningThoughts: "Tired day")
        self.mockHistorical.updateHighlightData(for: yesterday, data: highlight)

        self.viewModel.selectedDate = yesterday
        let data = self.viewModel.highlightViewData
        XCTAssertEqual(data.sleepQuality, .poor)
        XCTAssertFalse(data.isToday)
    }

    // MARK: - ReflectViewContract Data Isolation Tests

    func test_reflectViewData_defaultsToEmpty() {
        let data = self.viewModel.reflectViewData
        XCTAssertNil(data.journalText)
        XCTAssertNil(data.feeling)
        XCTAssertTrue(data.morningTodos.isEmpty)
        XCTAssertTrue(data.isToday)
    }

    func test_reflectViewData_reflectsSavedReflectData() {
        let reflect = ReflectData(journalText: "Great day", feeling: .calm)
        self.mockHistorical.updateReflectData(for: Date(), data: reflect)

        let data = self.viewModel.reflectViewData
        XCTAssertEqual(data.journalText, "Great day")
        XCTAssertEqual(data.feeling, .calm)
    }

    func test_reflectViewData_includesMorningTodosFromHighlight() {
        let todo = MindCheckEntry(category: .todo, text: "Exercise", context: .morning)
        let highlight = HighlightData(todos: [todo])
        self.mockHistorical.updateHighlightData(for: Date(), data: highlight)

        let data = self.viewModel.reflectViewData
        XCTAssertEqual(data.morningTodos.count, 1)
        XCTAssertEqual(data.morningTodos.first?.text, "Exercise")
    }

    func test_reflectViewData_cannotAccessMeals() {
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

        let data = self.viewModel.reflectViewData
        XCTAssertTrue(data.isToday)
    }

    func test_reflectViewData_cannotAccessSmileyState() {
        self.viewModel.smileyState = SmileyState(scale: 2.0, mood: .serene)
        let data = self.viewModel.reflectViewData
        XCTAssertTrue(data.isToday)
    }

    // MARK: - Date Sync Tests

    func test_tabData_syncWithSelectedDate() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let highlightYesterday = HighlightData(sleepQuality: .terrible)
        self.mockHistorical.updateHighlightData(for: yesterday, data: highlightYesterday)

        let reflectYesterday = ReflectData(feeling: .heavy)
        self.mockHistorical.updateReflectData(for: yesterday, data: reflectYesterday)

        // Today — no data
        XCTAssertNil(self.viewModel.highlightViewData.sleepQuality)
        XCTAssertNil(self.viewModel.reflectViewData.feeling)

        // Switch to yesterday
        self.viewModel.selectedDate = yesterday
        XCTAssertEqual(self.viewModel.highlightViewData.sleepQuality, .terrible)
        XCTAssertEqual(self.viewModel.reflectViewData.feeling, .heavy)
    }
}
