#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Regression tests ensuring archiveCurrentDay preserves all per-day user data.
    /// These tests exist because archiveCurrentDay previously dropped morningMindCheck
    /// and eveningMindCheck when re-archiving a snapshot with new meal data.
    @MainActor
    final class ArchiveRegressionTests: XCTestCase {
        // MARK: - Properties

        var service: HistoricalDataService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.service = HistoricalDataService(
                persistenceService: MockPersistenceService(),
                authService: MockAuthService(),
                syncService: MockCloudSyncService()
            )
        }

        override func tearDown() {
            self.service = nil
            super.tearDown()
        }

        // MARK: - Mind Check preservation

        func test_archiveCurrentDay_preservesMorningMindCheck() {
            let today = Calendar.current.startOfDay(for: Date())
            let entries = [MindCheckEntry(category: .todo, text: "Buy milk", context: .morning)]
            self.service.updateMorningMindCheck(for: today, entries: entries)

            // Re-archive with new meal data — should NOT wipe morningMindCheck
            self.service.archiveCurrentDay(meals: [], state: .neutral, date: today)

            let snapshot = self.service.getSnapshot(for: today)
            XCTAssertNotNil(snapshot?.morningMindCheck, "archiveCurrentDay must preserve morningMindCheck")
            XCTAssertEqual(snapshot?.morningMindCheck?.count, 1)
        }

        func test_archiveCurrentDay_preservesEveningMindCheck() {
            let today = Calendar.current.startOfDay(for: Date())
            let entries = [MindCheckEntry(category: .gratitude, text: "Good workout", context: .evening)]
            self.service.updateEveningMindCheck(for: today, entries: entries)

            self.service.archiveCurrentDay(meals: [], state: .neutral, date: today)

            let snapshot = self.service.getSnapshot(for: today)
            XCTAssertNotNil(snapshot?.eveningMindCheck, "archiveCurrentDay must preserve eveningMindCheck")
            XCTAssertEqual(snapshot?.eveningMindCheck?.count, 1)
        }

        func test_archiveCurrentDay_preservesHighlightData() {
            let today = Calendar.current.startOfDay(for: Date())
            var highlight = HighlightData()
            highlight.sleepQuality = .great
            highlight.morningThoughts = "Ready to go"
            self.service.updateHighlightData(for: today, data: highlight)

            self.service.archiveCurrentDay(meals: [], state: .neutral, date: today)

            let snapshot = self.service.getSnapshot(for: today)
            XCTAssertEqual(snapshot?.highlightData?.sleepQuality, .great)
            XCTAssertEqual(snapshot?.highlightData?.morningThoughts, "Ready to go")
        }

        func test_archiveCurrentDay_preservesReflectData() {
            let today = Calendar.current.startOfDay(for: Date())
            var reflect = ReflectData()
            reflect.journalText = "Productive day"
            reflect.feeling = .calm
            self.service.updateReflectData(for: today, data: reflect)

            self.service.archiveCurrentDay(meals: [], state: .neutral, date: today)

            let snapshot = self.service.getSnapshot(for: today)
            XCTAssertEqual(snapshot?.reflectData?.journalText, "Productive day")
            XCTAssertEqual(snapshot?.reflectData?.feeling, .calm)
        }

        func test_archiveCurrentDay_preservesExistingReflection() {
            let today = Calendar.current.startOfDay(for: Date())
            let reflection = DailyReflection(sleepQuality: .good)
            self.service.updateReflection(for: today, reflection: reflection)

            self.service.archiveCurrentDay(meals: [], state: .neutral, date: today)

            let snapshot = self.service.getSnapshot(for: today)
            XCTAssertEqual(snapshot?.reflection?.sleepQuality, .good)
        }

        func test_archiveCurrentDay_multipleRearchives_neverDropsUserData() {
            let today = Calendar.current.startOfDay(for: Date())
            let entries = [MindCheckEntry(category: .todo, text: "Task", context: .morning)]
            var highlight = HighlightData()
            highlight.sleepQuality = .poor

            self.service.updateMorningMindCheck(for: today, entries: entries)
            self.service.updateHighlightData(for: today, data: highlight)

            // Simulate multiple archives (e.g. multiple meal additions during the day)
            for _ in 0..<3 {
                self.service.archiveCurrentDay(meals: [], state: .neutral, date: today)
            }

            let snapshot = self.service.getSnapshot(for: today)
            XCTAssertEqual(snapshot?.morningMindCheck?.count, 1, "morningMindCheck must survive multiple re-archives")
            XCTAssertEqual(
                snapshot?.highlightData?.sleepQuality,
                .poor,
                "highlightData must survive multiple re-archives"
            )
        }
    }
#endif
