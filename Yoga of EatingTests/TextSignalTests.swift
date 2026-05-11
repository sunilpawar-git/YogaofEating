#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class TextSignalTests: XCTestCase {
        // MARK: - Enum completeness

        func test_allCases_haveNonEmptyDisplayName() {
            for signal in TextSignal.allCases {
                XCTAssertFalse(signal.displayName.isEmpty, "Missing displayName for \(signal)")
            }
        }

        func test_rawValues_areDistinct() {
            let rawValues = TextSignal.allCases.map(\.rawValue)
            XCTAssertEqual(rawValues.count, Set(rawValues).count)
        }

        func test_hasAtLeastSevenCases() {
            XCTAssertGreaterThanOrEqual(TextSignal.allCases.count, 7)
        }

        // MARK: - Codable

        func test_codableRoundTrip_allCases() throws {
            for signal in TextSignal.allCases {
                let data = try JSONEncoder().encode(signal)
                let decoded = try JSONDecoder().decode(TextSignal.self, from: data)
                XCTAssertEqual(signal, decoded, "Codable round-trip failed for \(signal)")
            }
        }

        func test_arrayOfSignals_codableRoundTrip() throws {
            let signals: [TextSignal] = [.grateful, .clear, .stressed, .neutral]
            let data = try JSONEncoder().encode(signals)
            let decoded = try JSONDecoder().decode([TextSignal].self, from: data)
            XCTAssertEqual(signals, decoded)
        }

        // MARK: - Specific cases

        func test_neutral_exists() {
            XCTAssertNotNil(TextSignal(rawValue: "neutral"))
        }

        func test_grateful_exists() {
            XCTAssertNotNil(TextSignal(rawValue: "grateful"))
        }

        func test_stressed_exists() {
            XCTAssertNotNil(TextSignal(rawValue: "stressed"))
        }

        func test_overwhelmed_exists() {
            XCTAssertNotNil(TextSignal(rawValue: "overwhelmed"))
        }

        func test_clear_exists() {
            XCTAssertNotNil(TextSignal(rawValue: "clear"))
        }

        func test_agentive_exists() {
            XCTAssertNotNil(TextSignal(rawValue: "agentive"))
        }

        func test_selfCompassionate_exists() {
            XCTAssertNotNil(TextSignal(rawValue: "selfCompassionate"))
        }

        // MARK: - SynthesisTrigger enum

        func test_synthesisTrigger_hasAtLeastSixCases() {
            XCTAssertGreaterThanOrEqual(SynthesisTrigger.allCases.count, 6)
        }

        func test_synthesisTrigger_rawValues_areDistinct() {
            let rawValues = SynthesisTrigger.allCases.map(\.rawValue)
            XCTAssertEqual(rawValues.count, Set(rawValues).count)
        }

        func test_synthesisTrigger_codableRoundTrip() throws {
            for trigger in SynthesisTrigger.allCases {
                let data = try JSONEncoder().encode(trigger)
                let decoded = try JSONDecoder().decode(SynthesisTrigger.self, from: data)
                XCTAssertEqual(trigger, decoded)
            }
        }

        func test_sleepLogged_trigger_exists() {
            XCTAssertNotNil(SynthesisTrigger(rawValue: "sleepLogged"))
        }

        func test_mealUpdated_trigger_exists() {
            XCTAssertNotNil(SynthesisTrigger(rawValue: "mealUpdated"))
        }
    }

#endif
