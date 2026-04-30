#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Unit tests for MainViewModel+Reflect mutation helpers.
    /// All tests use MockHistoricalDataService to prevent disk I/O.
    @MainActor
    final class MainViewModelReflectTests: XCTestCase {
        // MARK: - Properties

        var sut: MainViewModel!
        var mockHistorical: MockHistoricalDataService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.mockHistorical = MockHistoricalDataService()
            self.sut = MainViewModel(
                logicService: MockMealLogicService(),
                persistenceService: MockPersistenceService(),
                historicalService: self.mockHistorical,
                skipDataLoading: true
            )
        }

        override func tearDown() {
            self.sut = nil
            self.mockHistorical = nil
            super.tearDown()
        }

        // MARK: - isViewingToday guard

        func test_updateReflectJournalText_noOp_whenNotViewingToday() {
            self.sut.navigateToPreviousDay()
            self.sut.updateReflectJournalText("Great day")
            XCTAssertNil(self.mockHistorical.getSnapshot(for: self.sut.selectedDate)?.reflectData)
        }

        func test_updateReflectFeeling_noOp_whenNotViewingToday() {
            self.sut.navigateToPreviousDay()
            self.sut.updateReflectFeeling(.great)
            XCTAssertNil(self.mockHistorical.getSnapshot(for: self.sut.selectedDate)?.reflectData)
        }

        func test_toggleTodoAccomplished_noOp_whenNotViewingToday() {
            // Seed a today todo, then navigate away
            self.sut.addHighlightTodo("Morning run")
            let today = Calendar.current.startOfDay(for: Date())
            // swiftlint:disable:next force_unwrapping
            let todayId = self.mockHistorical.getSnapshot(for: today)!.highlightData!.todos[0].id
            self.sut.navigateToPreviousDay()
            self.sut.toggleTodoAccomplished(todayId)
            // Today's todo should still be not accomplished (nil = never set)
            let todayHighlight = self.mockHistorical.getSnapshot(for: today)?.highlightData
            let accomplished = todayHighlight?.todos[0].isAccomplished
            XCTAssertNil(accomplished)
        }

        // MARK: - Journal Text

        func test_updateReflectJournalText_persistsToSnapshot() {
            self.sut.updateReflectJournalText("Today was productive")
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertEqual(snapshot?.reflectData?.journalText, "Today was productive")
        }

        func test_updateReflectJournalText_emptyString_setsNil() {
            self.sut.updateReflectJournalText("Some text")
            self.sut.updateReflectJournalText("")
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertNil(snapshot?.reflectData?.journalText)
        }

        func test_updateReflectJournalText_updatesExistingEntry() {
            self.sut.updateReflectJournalText("First draft")
            self.sut.updateReflectJournalText("Revised draft")
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertEqual(snapshot?.reflectData?.journalText, "Revised draft")
        }

        // MARK: - Feeling

        func test_updateReflectFeeling_persistsToSnapshot() {
            self.sut.updateReflectFeeling(.calm)
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertEqual(snapshot?.reflectData?.feeling, .calm)
        }

        func test_updateReflectFeeling_nil_clearsFeelingInSnapshot() {
            self.sut.updateReflectFeeling(.great)
            self.sut.updateReflectFeeling(nil)
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertNil(snapshot?.reflectData?.feeling)
        }

        func test_updateReflectFeeling_alsoMirrorsToLegacyReflection() {
            self.sut.updateReflectFeeling(.ok)
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertEqual(snapshot?.reflection?.feeling, .ok)
        }

        func test_updateReflectFeeling_nil_clearsLegacyReflectionFeeling() {
            self.sut.updateReflectFeeling(.tired)
            self.sut.updateReflectFeeling(nil)
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertNil(snapshot?.reflection?.feeling)
        }

        // MARK: - Toggle Todo Accomplished

        func test_toggleTodoAccomplished_setsAccomplishedTrue() {
            self.sut.addHighlightTodo("Task A")
            let id = self.mockHistorical.getSnapshot(for: Date())!.highlightData!.todos[0].id
            self.sut.toggleTodoAccomplished(id)
            let accomplished = self.mockHistorical.getSnapshot(for: Date())?.highlightData?.todos[0].isAccomplished
            XCTAssertEqual(accomplished, true)
        }

        func test_toggleTodoAccomplished_togglesBackToFalse() {
            self.sut.addHighlightTodo("Task A")
            let id = self.mockHistorical.getSnapshot(for: Date())!.highlightData!.todos[0].id
            self.sut.toggleTodoAccomplished(id)
            self.sut.toggleTodoAccomplished(id)
            let accomplished = self.mockHistorical.getSnapshot(for: Date())?.highlightData?.todos[0].isAccomplished
            XCTAssertEqual(accomplished, false)
        }

        func test_toggleTodoAccomplished_unknownId_doesNothing() {
            self.sut.addHighlightTodo("Task A")
            self.sut.toggleTodoAccomplished(UUID())
            let count = self.mockHistorical.getSnapshot(for: Date())?.highlightData?.todos.count
            XCTAssertEqual(count, 1)
        }

        func test_toggleTodoAccomplished_updatesHighlightDataAsSourceOfTruth() {
            self.sut.addHighlightTodo("Morning run")
            let id = self.mockHistorical.getSnapshot(for: Date())!.highlightData!.todos[0].id
            self.sut.toggleTodoAccomplished(id)
            // ReflectView contract also reflects the change via HighlightData
            let reflectContract = self.sut.reflectViewData
            let todo = reflectContract.morningTodos.first(where: { $0.id == id })
            XCTAssertEqual(todo?.isAccomplished, true)
        }
    }
#endif
