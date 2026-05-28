#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Phase 4 TDD: SnapshotPayloadBuilder must include raw morningThoughts and journalEntry
    /// so Gemini receives actual text rather than keyword-extracted signals.
    final class SnapshotPayloadRawTextTests: XCTestCase {
        private let today = Calendar.current.startOfDay(for: Date())

        // MARK: - Raw text in server payload

        // Red: payload currently omits raw morningThoughts
        func test_snapshotPayload_includesRawMorningThoughts() {
            let highlight = HighlightData(morningThoughts: "Feeling focused and ready today")
            let snap = DailySmileySnapshotBuilder()
                .withDate(self.today)
                .withHighlightData(highlight)
                .build()
            let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: self.today)
            XCTAssertEqual(
                payload[0]["morningThoughts"] as? String,
                "Feeling focused and ready today"
            )
        }

        // Red: payload currently omits raw journalEntry
        func test_snapshotPayload_includesRawJournalEntry() {
            let reflect = ReflectData(journalText: "Dinner was heavy, going to sleep early")
            let snap = DailySmileySnapshotBuilder()
                .withDate(self.today)
                .withReflectData(reflect)
                .build()
            let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: self.today)
            XCTAssertEqual(
                payload[0]["journalEntry"] as? String,
                "Dinner was heavy, going to sleep early"
            )
        }

        // Red: empty morningThoughts should be omitted (not sent as empty string)
        func test_snapshotPayload_omitsMorningThoughts_whenNil() {
            let snap = DailySmileySnapshotBuilder().withDate(self.today).build()
            let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: self.today)
            XCTAssertNil(payload[0]["morningThoughts"])
        }

        func test_snapshotPayload_omitsJournalEntry_whenNil() {
            let snap = DailySmileySnapshotBuilder().withDate(self.today).build()
            let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: self.today)
            XCTAssertNil(payload[0]["journalEntry"])
        }

        // MARK: - Local fallback still uses keyword signals (regression)

        // Verifies that DailySynthesisEngine still reads keyword text signals from
        // highlightData.textSignals — the local synthesis path is unchanged by Phase 4.
        func test_textSignalExtractor_stillUsedByLocalFallbackPath() {
            let engine = DailySynthesisEngine()
            var highlight = HighlightData()
            highlight.textSignals = [.stressed, .grateful]
            let synthesis = engine.synthesize(
                meals: [],
                highlightData: highlight,
                reflectData: nil,
                appleSleepData: nil
            )
            XCTAssert(synthesis.textSignals.contains(.stressed), "Local synthesis must preserve keyword signals")
            XCTAssert(synthesis.textSignals.contains(.grateful), "Local synthesis must preserve keyword signals")
        }
    }

#endif
