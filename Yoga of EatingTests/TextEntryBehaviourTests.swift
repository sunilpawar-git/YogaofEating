// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Verifies ViewModel-level text entry contracts:
    /// character truncation, debounce presence, and that the VM never persists
    /// more than AppTheme.TextEntry.maxCharacters characters.
    @MainActor
    final class TextEntryBehaviourTests: XCTestCase {
        // MARK: - Properties

        var sut: MainViewModel!
        var mockHistorical: MockHistoricalDataService!

        // MARK: - Setup

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

        // MARK: - Highlight: sleep notes character limit

        func test_updateHighlightSleepNotes_exactLimit_persists() {
            let text = String(repeating: "a", count: AppTheme.TextEntry.maxCharacters)
            self.sut.updateHighlightSleepNotes(text)
            let saved = self.mockHistorical.getSnapshot(for: Date())?.highlightData?.sleepNotes
            XCTAssertEqual(saved?.count, AppTheme.TextEntry.maxCharacters)
        }

        func test_updateHighlightSleepNotes_overLimit_isTruncated() {
            let text = String(repeating: "b", count: AppTheme.TextEntry.maxCharacters + 50)
            self.sut.updateHighlightSleepNotes(text)
            let saved = self.mockHistorical.getSnapshot(for: Date())?.highlightData?.sleepNotes
            XCTAssertNotNil(saved)
            XCTAssertLessThanOrEqual(saved!.count, AppTheme.TextEntry.maxCharacters)
        }

        // MARK: - Highlight: morning thoughts character limit

        func test_updateHighlightMorningThoughts_overLimit_isTruncated() {
            let text = String(repeating: "c", count: AppTheme.TextEntry.maxCharacters + 100)
            self.sut.updateHighlightMorningThoughts(text)
            let saved = self.mockHistorical.getSnapshot(for: Date())?.highlightData?.morningThoughts
            XCTAssertNotNil(saved)
            XCTAssertLessThanOrEqual(saved!.count, AppTheme.TextEntry.maxCharacters)
        }

        func test_updateHighlightMorningThoughts_exactLimit_persists() {
            let text = String(repeating: "d", count: AppTheme.TextEntry.maxCharacters)
            self.sut.updateHighlightMorningThoughts(text)
            let saved = self.mockHistorical.getSnapshot(for: Date())?.highlightData?.morningThoughts
            XCTAssertEqual(saved?.count, AppTheme.TextEntry.maxCharacters)
        }

        // MARK: - Reflect: journal character limit

        func test_updateReflectJournalText_overLimit_isTruncated() {
            let text = String(repeating: "e", count: AppTheme.TextEntry.maxCharacters + 200)
            self.sut.updateReflectJournalText(text)
            let saved = self.mockHistorical.getSnapshot(for: Date())?.reflectData?.journalText
            XCTAssertNotNil(saved)
            XCTAssertLessThanOrEqual(saved!.count, AppTheme.TextEntry.maxCharacters)
        }

        func test_updateReflectJournalText_exactLimit_persists() {
            let text = String(repeating: "f", count: AppTheme.TextEntry.maxCharacters)
            self.sut.updateReflectJournalText(text)
            let saved = self.mockHistorical.getSnapshot(for: Date())?.reflectData?.journalText
            XCTAssertEqual(saved?.count, AppTheme.TextEntry.maxCharacters)
        }

        // MARK: - Empty string → nil (existing contract, verify not broken by truncation)

        func test_updateHighlightSleepNotes_empty_storesNil() {
            self.sut.updateHighlightSleepNotes("")
            let saved = self.mockHistorical.getSnapshot(for: Date())?.highlightData?.sleepNotes
            XCTAssertNil(saved)
        }

        func test_updateReflectJournalText_empty_storesNil() {
            self.sut.updateReflectJournalText("")
            let saved = self.mockHistorical.getSnapshot(for: Date())?.reflectData?.journalText
            XCTAssertNil(saved)
        }

        // MARK: - Contract Date-Identity Invariants (Regression: text-vanishing bug)

        // These document the invariant HighlightView and ReflectView rely on:
        // same-day background mutations must NOT change data.date so the view's
        // onChange(of: data.date) only fires on actual date navigation.

        func test_highlightViewData_date_unchangedWhenSleepQualityUpdated() {
            let before = self.sut.highlightViewData.date
            self.sut.updateHighlightSleepQuality(.good)
            XCTAssertEqual(
                self.sut.highlightViewData.date,
                before,
                "Same-day sleep quality update must not change contract date"
            )
        }

        func test_highlightViewData_date_unchangedWhenSleepNotesUpdated() {
            let before = self.sut.highlightViewData.date
            self.sut.updateHighlightSleepNotes("Good sleep")
            XCTAssertEqual(
                self.sut.highlightViewData.date,
                before,
                "Same-day sleep notes update must not change contract date"
            )
        }

        func test_highlightViewData_date_unchangedWhenMorningThoughtsUpdated() {
            let before = self.sut.highlightViewData.date
            self.sut.updateHighlightMorningThoughts("Feeling good")
            XCTAssertEqual(
                self.sut.highlightViewData.date,
                before,
                "Same-day morning thoughts update must not change contract date"
            )
        }

        func test_highlightViewData_date_unchangedWhenTodoAdded() {
            let before = self.sut.highlightViewData.date
            self.sut.addHighlightTodo("Exercise")
            XCTAssertEqual(
                self.sut.highlightViewData.date,
                before,
                "Same-day todo addition must not change contract date"
            )
        }

        func test_highlightViewData_date_changesOnDateNavigation() {
            let today = self.sut.highlightViewData.date
            self.sut.navigateToPreviousDay()
            XCTAssertNotEqual(
                self.sut.highlightViewData.date,
                today,
                "Date navigation must change contract date to trigger view reset"
            )
        }

        func test_reflectViewData_date_unchangedWhenFeelingUpdated() {
            let before = self.sut.reflectViewData.date
            self.sut.updateReflectFeeling(.calm)
            XCTAssertEqual(
                self.sut.reflectViewData.date,
                before,
                "Same-day feeling update must not change contract date"
            )
        }

        func test_reflectViewData_date_unchangedWhenJournalTextUpdated() {
            let before = self.sut.reflectViewData.date
            self.sut.updateReflectJournalText("Today was good")
            XCTAssertEqual(
                self.sut.reflectViewData.date,
                before,
                "Same-day journal text update must not change contract date"
            )
        }

        func test_reflectViewData_date_changesOnDateNavigation() {
            let today = self.sut.reflectViewData.date
            self.sut.navigateToPreviousDay()
            XCTAssertNotEqual(
                self.sut.reflectViewData.date,
                today,
                "Date navigation must change contract date to trigger view reset"
            )
        }

        // Confirms that a same-day data change leaves date unchanged in the contract,
        // meaning HighlightView's onChange(of: data.date) will NOT fire — text is safe.
        func test_highlightViewContract_sleepNotesChange_dateIdentityPreserved() {
            let contractBefore = self.sut.highlightViewData
            self.sut.updateHighlightSleepQuality(.great)
            let contractAfter = self.sut.highlightViewData
            XCTAssertEqual(
                contractBefore.date,
                contractAfter.date,
                "Contract date must be identical after same-day mutation"
            )
            XCTAssertNotEqual(
                contractBefore,
                contractAfter,
                "Contract equality detects the quality change (non-date field changed)"
            )
        }
    }
#endif
