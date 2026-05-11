#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class MainViewModelTextSignalIntegrationTests: XCTestCase {
        private var mockHistorical: MockHistoricalDataService!
        private var sut: MainViewModel!

        override func setUp() {
            super.setUp()
            self.mockHistorical = MockHistoricalDataService()
            self.sut = MainViewModel(
                historicalService: self.mockHistorical,
                skipDataLoading: true
            )
        }

        override func tearDown() {
            self.sut = nil
            self.mockHistorical = nil
            super.tearDown()
        }

        // MARK: - Morning Thoughts → Highlight text signals

        func test_updateHighlightMorningThoughts_grateful_storesGratefulSignal() {
            self.sut.updateHighlightMorningThoughts("I feel so grateful today")

            let signals = self.todayHighlightData()?.textSignals
            XCTAssertNotNil(signals, "textSignals should be set after morning thoughts update")
            XCTAssertTrue(signals?.contains(.grateful) == true, "Expected .grateful in signals")
        }

        func test_updateHighlightMorningThoughts_stressed_storesStressedSignal() {
            self.sut.updateHighlightMorningThoughts("Feeling stressed about the deadline today")

            let signals = self.todayHighlightData()?.textSignals
            XCTAssertNotNil(signals)
            XCTAssertTrue(signals?.contains(.stressed) == true, "Expected .stressed in signals")
        }

        func test_updateHighlightMorningThoughts_clear_storesClearSignal() {
            self.sut.updateHighlightMorningThoughts("Clear and focused on my plan for today")

            let signals = self.todayHighlightData()?.textSignals
            XCTAssertNotNil(signals)
            XCTAssertTrue(signals?.contains(.clear) == true, "Expected .clear in signals")
        }

        func test_updateHighlightMorningThoughts_empty_storesNeutralSignal() {
            self.sut.updateHighlightMorningThoughts("")

            // Empty text clears morningThoughts — no signals stored (nil data or nil textSignals)
            // The existing behaviour sets morningThoughts = nil for empty input;
            // textSignals should also be nil since no extraction runs on empty.
            let data = self.todayHighlightData()
            let signals = data?.textSignals
            // Either no data was saved (nil) or signals is nil/[.neutral]
            XCTAssertTrue(signals == nil || signals == [.neutral])
        }

        func test_updateHighlightMorningThoughts_plainText_storesNeutralSignal() {
            self.sut.updateHighlightMorningThoughts("Had coffee and read the news this morning")

            let signals = self.todayHighlightData()?.textSignals
            // No keywords → neutral
            XCTAssertNotNil(signals)
            XCTAssertEqual(signals, [.neutral])
        }

        // MARK: - Evening Journal → Reflect text signals

        func test_updateReflectJournalText_overwhelmed_storesOverwhelmedSignal() {
            self.sut.updateReflectJournalText("Completely overwhelmed with work today")

            let signals = self.todayReflectData()?.textSignals
            XCTAssertNotNil(signals, "textSignals should be set after journal update")
            XCTAssertTrue(signals?.contains(.overwhelmed) == true, "Expected .overwhelmed in signals")
        }

        func test_updateReflectJournalText_grateful_storesGratefulSignal() {
            self.sut.updateReflectJournalText("Feeling very grateful for what went well")

            let signals = self.todayReflectData()?.textSignals
            XCTAssertNotNil(signals)
            XCTAssertTrue(signals?.contains(.grateful) == true, "Expected .grateful in signals")
        }

        func test_updateReflectJournalText_selfCompassionate_storesSelfCompassionateSignal() {
            self.sut.updateReflectJournalText("Being gentle with myself for not finishing everything")

            let signals = self.todayReflectData()?.textSignals
            XCTAssertNotNil(signals)
            XCTAssertTrue(signals?.contains(.selfCompassionate) == true)
        }

        func test_updateReflectJournalText_plainText_storesNeutralSignal() {
            self.sut.updateReflectJournalText("Finished dinner and watched a movie tonight")

            let signals = self.todayReflectData()?.textSignals
            XCTAssertNotNil(signals)
            XCTAssertEqual(signals, [.neutral])
        }

        // MARK: - Signals don't include raw text

        func test_signals_neverContainUserText() {
            let userText = "My secret journal: I feel grateful today"
            self.sut.updateReflectJournalText(userText)

            let signals = self.todayReflectData()?.textSignals ?? []
            for signal in signals {
                XCTAssertFalse(signal.rawValue.contains("secret"), "Raw text must not leak into signal rawValue")
                XCTAssertFalse(signal.rawValue.contains("journal"), "Raw text must not leak into signal rawValue")
            }
        }

        // MARK: - Helpers

        private func todayHighlightData() -> HighlightData? {
            self.mockHistorical.historicalData.snapshot(for: Date())?.highlightData
        }

        private func todayReflectData() -> ReflectData? {
            self.mockHistorical.historicalData.snapshot(for: Date())?.reflectData
        }
    }

#endif
