#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Unit tests for MainViewModel+Highlight mutation helpers.
    /// All tests use MockHistoricalDataService to prevent disk I/O.
    @MainActor
    final class MainViewModelHighlightTests: XCTestCase {
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

        func test_updateHighlightSleepQuality_noOp_whenNotViewingToday() {
            self.sut.navigateToPreviousDay()
            self.sut.updateHighlightSleepQuality(.good)
            XCTAssertNil(self.mockHistorical.getSnapshot(for: self.sut.selectedDate)?.highlightData)
        }

        func test_updateHighlightSleepNotes_noOp_whenNotViewingToday() {
            self.sut.navigateToPreviousDay()
            self.sut.updateHighlightSleepNotes("some notes")
            XCTAssertNil(self.mockHistorical.getSnapshot(for: self.sut.selectedDate)?.highlightData)
        }

        func test_addHighlightTodo_noOp_whenNotViewingToday() {
            self.sut.navigateToPreviousDay()
            self.sut.addHighlightTodo("Buy milk")
            XCTAssertNil(self.mockHistorical.getSnapshot(for: self.sut.selectedDate)?.highlightData)
        }

        func test_removeHighlightTodo_noOp_whenNotViewingToday() {
            // Seed a todo via today's date first
            self.sut.addHighlightTodo("Task A")
            let id = self.mockHistorical.getSnapshot(for: Date())!.highlightData!.todos[0].id
            // Navigate away then try to remove
            self.sut.navigateToPreviousDay()
            self.sut.removeHighlightTodo(id)
            // Today's snapshot still has the todo
            let todaySnapshot = self.mockHistorical.getSnapshot(for: Calendar.current.startOfDay(for: Date()))
            XCTAssertEqual(todaySnapshot?.highlightData?.todos.count, 1)
        }

        func test_updateHighlightMorningThoughts_noOp_whenNotViewingToday() {
            self.sut.navigateToPreviousDay()
            self.sut.updateHighlightMorningThoughts("Good morning")
            XCTAssertNil(self.mockHistorical.getSnapshot(for: self.sut.selectedDate)?.highlightData)
        }

        // MARK: - Sleep Quality

        func test_updateHighlightSleepQuality_persistsToSnapshot() {
            self.sut.updateHighlightSleepQuality(.great)
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertEqual(snapshot?.highlightData?.sleepQuality, .great)
        }

        func test_updateHighlightSleepQuality_nil_clearsSleepQuality() {
            self.sut.updateHighlightSleepQuality(.good)
            self.sut.updateHighlightSleepQuality(nil)
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertNil(snapshot?.highlightData?.sleepQuality)
        }

        func test_updateHighlightSleepQuality_alsoMirrorsToLegacyReflection() {
            self.sut.updateHighlightSleepQuality(.poor)
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertEqual(snapshot?.reflection?.sleepQuality, .poor)
        }

        func test_updateHighlightSleepQuality_nil_clearsLegacyReflectionSleepQuality() {
            self.sut.updateHighlightSleepQuality(.good)
            self.sut.updateHighlightSleepQuality(nil)
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertNil(snapshot?.reflection?.sleepQuality)
        }

        // MARK: - Sleep Notes

        func test_updateHighlightSleepNotes_persistsToSnapshot() {
            self.sut.updateHighlightSleepNotes("Slept 7 hours")
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertEqual(snapshot?.highlightData?.sleepNotes, "Slept 7 hours")
        }

        func test_updateHighlightSleepNotes_emptyString_setsNil() {
            self.sut.updateHighlightSleepNotes("Some notes")
            self.sut.updateHighlightSleepNotes("")
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertNil(snapshot?.highlightData?.sleepNotes)
        }

        // MARK: - To-Do Items

        func test_addHighlightTodo_appendsEntry() {
            self.sut.addHighlightTodo("Meditate")
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertEqual(snapshot?.highlightData?.todos.count, 1)
            XCTAssertEqual(snapshot?.highlightData?.todos[0].text, "Meditate")
        }

        func test_addHighlightTodo_multipleEntries_allPersisted() {
            self.sut.addHighlightTodo("Task A")
            self.sut.addHighlightTodo("Task B")
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertEqual(snapshot?.highlightData?.todos.count, 2)
        }

        func test_addHighlightTodo_whitespaceOnly_doesNotAdd() {
            self.sut.addHighlightTodo("   ")
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertNil(snapshot?.highlightData)
        }

        func test_addHighlightTodo_trimsWhitespace() {
            self.sut.addHighlightTodo("  Read book  ")
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertEqual(snapshot?.highlightData?.todos[0].text, "Read book")
        }

        func test_removeHighlightTodo_removesById() {
            self.sut.addHighlightTodo("Task A")
            self.sut.addHighlightTodo("Task B")
            let todos = self.mockHistorical.getSnapshot(for: Date())!.highlightData!.todos
            let idToRemove = todos[0].id
            self.sut.removeHighlightTodo(idToRemove)
            let updated = self.mockHistorical.getSnapshot(for: Date())?.highlightData?.todos
            XCTAssertEqual(updated?.count, 1)
            XCTAssertFalse(updated?.contains(where: { $0.id == idToRemove }) ?? true)
        }

        func test_removeHighlightTodo_unknownId_doesNothing() {
            self.sut.addHighlightTodo("Task A")
            self.sut.removeHighlightTodo(UUID())
            let count = self.mockHistorical.getSnapshot(for: Date())?.highlightData?.todos.count
            XCTAssertEqual(count, 1)
        }

        // MARK: - Morning Thoughts

        func test_updateHighlightMorningThoughts_persistsText() {
            self.sut.updateHighlightMorningThoughts("Feeling great today")
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertEqual(snapshot?.highlightData?.morningThoughts, "Feeling great today")
        }

        func test_updateHighlightMorningThoughts_emptyString_setsNil() {
            self.sut.updateHighlightMorningThoughts("Some thoughts")
            self.sut.updateHighlightMorningThoughts("")
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertNil(snapshot?.highlightData?.morningThoughts)
        }
    }
#endif
