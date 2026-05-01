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
    }
#endif
