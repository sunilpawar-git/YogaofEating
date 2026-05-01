// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// TDD tests for the incomplete-todo carry-over feature.
    /// Feature: incomplete .todo entries from the previous day are
    /// automatically seeded into the next day's HighlightData.todos,
    /// each with carriedOverCount incremented by 1 and an age badge visible in the UI.
    @MainActor
    final class TodoCarryOverTests: XCTestCase {
        // MARK: - Properties

        var sut: HistoricalDataService!
        var mockPersistence: MockPersistenceService!
        var mockAuth: MockAuthService!
        var mockSync: MockCloudSyncService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.mockPersistence = MockPersistenceService()
            self.mockAuth = MockAuthService()
            self.mockSync = MockCloudSyncService()
            self.sut = HistoricalDataService(
                persistenceService: self.mockPersistence,
                authService: self.mockAuth,
                syncService: self.mockSync
            )
        }

        override func tearDown() {
            self.sut = nil
            self.mockPersistence = nil
            self.mockAuth = nil
            self.mockSync = nil
            super.tearDown()
        }

        // MARK: - MindCheckEntry.carriedOverCount field tests

        func test_carriedOverCount_isZeroForFreshTodo() {
            let entry = MindCheckEntry(category: .todo, text: "Fresh task", context: .morning)
            XCTAssertEqual(entry.carriedOverCount, 0)
        }

        func test_carriedOverCount_incrementsEachDayCarried() {
            let entry = MindCheckEntry(category: .todo, text: "Old task", context: .morning)
            let carried = entry.withCarriedOverCount(3)
            XCTAssertEqual(carried.carriedOverCount, 3)
        }

        func test_carriedOverCount_clampedAt365() {
            let entry = MindCheckEntry(category: .todo, text: "Ancient task", context: .morning)
            let clamped = entry.withCarriedOverCount(1000)
            XCTAssertEqual(clamped.carriedOverCount, 365, "Count should be clamped to 365 max")
        }

        func test_carriedOverCount_clampedAtZeroForNegative() {
            let entry = MindCheckEntry(category: .todo, text: "Task", context: .morning)
            let clamped = entry.withCarriedOverCount(-5)
            XCTAssertEqual(clamped.carriedOverCount, 0, "Count should not go below 0")
        }

        func test_mindCheckEntry_codableRoundTrip_withCarriedOverCount() throws {
            let original = MindCheckEntry(category: .todo, text: "Carry test", context: .morning)
            let carried = original.withCarriedOverCount(3)

            let data = try JSONEncoder().encode(carried)
            let decoded = try JSONDecoder().decode(MindCheckEntry.self, from: data)

            XCTAssertEqual(decoded.carriedOverCount, 3)
            XCTAssertEqual(decoded.text, "Carry test")
        }

        func test_mindCheckEntry_decodesLegacyJSON_withoutCarriedOverCount_defaultsToZero() throws {
            // Simulate JSON produced before the carriedOverCount field was added
            let legacyJSON = """
            {
                "id": "12345678-1234-1234-1234-123456789012",
                "category": "todo",
                "text": "Old todo",
                "timestamp": 0,
                "context": "morning"
            }
            """.data(using: .utf8)!

            let decoded = try JSONDecoder().decode(MindCheckEntry.self, from: legacyJSON)
            XCTAssertEqual(
                decoded.carriedOverCount, 0,
                "Legacy data without carriedOverCount should decode to 0"
            )
        }

        // MARK: - HistoricalDataService.incompleteTodosForCarryOver tests

        func test_incompleteTodosForCarryOver_returnsOnlyIncompleteTodos() {
            let date = Calendar.current.startOfDay(for: Date())
            let incomplete = MindCheckEntry(
                category: .todo, text: "Unfinished", context: .morning, isAccomplished: nil
            )
            let done = MindCheckEntry(
                category: .todo, text: "Done task", context: .morning, isAccomplished: true
            )
            let highlight = HighlightData(todos: [incomplete, done])
            self.seedHighlightData(highlight, on: date)

            let result = self.sut.incompleteTodosForCarryOver(from: date)

            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first?.text, "Unfinished")
        }

        func test_incompleteTodosForCarryOver_doesNotCarryCompletedTodos() {
            let date = Calendar.current.startOfDay(for: Date())
            let done = MindCheckEntry(
                category: .todo, text: "Completed", context: .morning, isAccomplished: true
            )
            self.seedHighlightData(HighlightData(todos: [done]), on: date)

            let result = self.sut.incompleteTodosForCarryOver(from: date)

            XCTAssertTrue(result.isEmpty)
        }

        func test_incompleteTodosForCarryOver_doesNotCarryExplicitlyMarkedFalse() {
            let date = Calendar.current.startOfDay(for: Date())
            // isAccomplished == false means "reviewed and not done" — still incomplete, carry it
            let reviewed = MindCheckEntry(
                category: .todo, text: "Reviewed but not done", context: .morning, isAccomplished: false
            )
            self.seedHighlightData(HighlightData(todos: [reviewed]), on: date)

            let result = self.sut.incompleteTodosForCarryOver(from: date)

            XCTAssertEqual(result.count, 1, "isAccomplished == false is still incomplete and should carry")
        }

        func test_incompleteTodosForCarryOver_incrementsCarriedOverCount() {
            let date = Calendar.current.startOfDay(for: Date())
            let todo = MindCheckEntry(category: .todo, text: "Task", context: .morning)
                .withCarriedOverCount(2)
            self.seedHighlightData(HighlightData(todos: [todo]), on: date)

            let result = self.sut.incompleteTodosForCarryOver(from: date)

            XCTAssertEqual(result.first?.carriedOverCount, 3, "Count should be incremented by 1")
        }

        func test_incompleteTodosForCarryOver_emptyWhenNoSnapshot() {
            let date = Calendar.current.startOfDay(for: Date())
            // No snapshot seeded — should return empty safely
            let result = self.sut.incompleteTodosForCarryOver(from: date)
            XCTAssertTrue(result.isEmpty)
        }

        func test_incompleteTodosForCarryOver_emptyWhenNoHighlightData() {
            let date = Calendar.current.startOfDay(for: Date())
            // Snapshot exists but has no highlightData
            let snapshot = DailySmileySnapshot(
                id: UUID(), date: date, smileyState: .neutral,
                meals: [], mealCount: 0, averageHealthScore: 0.5
            )
            self.sut.historicalData.addOrUpdate(snapshot: snapshot)

            let result = self.sut.incompleteTodosForCarryOver(from: date)
            XCTAssertTrue(result.isEmpty)
        }

        // MARK: - MainViewModel.resetDay() carry-over integration

        func test_resetDay_populatesTodaySnapshotWithCarriedTodos() {
            let mockHistorical = MockHistoricalDataService()

            // Seed yesterday's snapshot with an incomplete todo
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let todo = MindCheckEntry(category: .todo, text: "Carry me", context: .morning)
            let highlight = HighlightData(todos: [todo])
            mockHistorical.updateHighlightData(for: yesterday, data: highlight)

            let vm = MainViewModel(
                historicalService: mockHistorical,
                skipDataLoading: true
            )
            vm.lastResetDate = yesterday

            vm.resetDay()

            // Today's snapshot should now have the carried todo
            let today = Calendar.current.startOfDay(for: Date())
            let todayHighlight = mockHistorical.getSnapshot(for: today)?.highlightData
            XCTAssertNotNil(todayHighlight, "Today's snapshot should have highlight data after carry-over")
            XCTAssertEqual(todayHighlight?.todos.count, 1)
            XCTAssertEqual(todayHighlight?.todos.first?.text, "Carry me")
            XCTAssertEqual(todayHighlight?.todos.first?.carriedOverCount, 1)
        }

        func test_resetDay_doesNotCreateHighlightDataWhenNoIncompleteTodos() {
            let mockHistorical = MockHistoricalDataService()

            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            // All todos are completed
            let done = MindCheckEntry(category: .todo, text: "Done", context: .morning, isAccomplished: true)
            mockHistorical.updateHighlightData(for: yesterday, data: HighlightData(todos: [done]))

            let vm = MainViewModel(historicalService: mockHistorical, skipDataLoading: true)
            vm.lastResetDate = yesterday

            vm.resetDay()

            let today = Calendar.current.startOfDay(for: Date())
            let todayHighlight = mockHistorical.getSnapshot(for: today)?.highlightData
            // Either nil or empty todos — no incomplete carry
            let todoCount = todayHighlight?.todos.count ?? 0
            XCTAssertEqual(todoCount, 0, "No incomplete todos means today should have none")
        }

        // MARK: - Helpers

        private func seedHighlightData(_ data: HighlightData, on date: Date) {
            let snapshot = DailySmileySnapshot(
                id: UUID(), date: date, smileyState: .neutral,
                meals: [], mealCount: 0, averageHealthScore: 0.5,
                highlightData: data
            )
            self.sut.historicalData.addOrUpdate(snapshot: snapshot)
        }
    }
#endif
