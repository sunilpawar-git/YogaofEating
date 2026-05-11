#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class TextSignalExtractorTests: XCTestCase {
        private let sut = TextSignalExtractor()

        // MARK: - Empty / blank input

        func test_emptyString_returnsNeutral() {
            XCTAssertEqual(self.sut.extractSignals(from: "", context: .morningThoughts), [.neutral])
        }

        func test_whitespaceOnly_returnsNeutral() {
            XCTAssertEqual(self.sut.extractSignals(from: "   \n  ", context: .eveningJournal), [.neutral])
        }

        // MARK: - Grateful signal

        func test_gratefulKeyword_returnsGrateful() {
            let signals = self.sut.extractSignals(from: "I feel so grateful today", context: .morningThoughts)
            XCTAssertTrue(signals.contains(.grateful))
        }

        func test_thankfulKeyword_returnsGrateful() {
            let signals = self.sut.extractSignals(from: "I am thankful for my family", context: .eveningJournal)
            XCTAssertTrue(signals.contains(.grateful))
        }

        // MARK: - Overwhelmed signal

        func test_overwhelmedKeyword_returnsOverwhelmed() {
            let signals = self.sut.extractSignals(from: "Completely overwhelmed with work", context: .eveningJournal)
            XCTAssertTrue(signals.contains(.overwhelmed))
        }

        func test_tooMuchKeyword_returnsOverwhelmed() {
            let signals = self.sut.extractSignals(from: "There is just too much to handle", context: .eveningJournal)
            XCTAssertTrue(signals.contains(.overwhelmed))
        }

        // MARK: - Stressed signal

        func test_stressedKeyword_returnsStressed() {
            let signals = self.sut.extractSignals(
                from: "Feeling stressed about the deadline",
                context: .morningThoughts
            )
            XCTAssertTrue(signals.contains(.stressed))
        }

        func test_anxiousKeyword_returnsStressed() {
            let signals = self.sut.extractSignals(from: "A bit anxious today but ready", context: .morningThoughts)
            XCTAssertTrue(signals.contains(.stressed))
        }

        // MARK: - Clear signal

        func test_clearKeyword_returnsClear() {
            let signals = self.sut.extractSignals(from: "My mind is clear and focused", context: .morningThoughts)
            XCTAssertTrue(signals.contains(.clear))
        }

        func test_focusedKeyword_returnsClear() {
            let signals = self.sut.extractSignals(from: "Feeling focused on my goals today", context: .morningThoughts)
            XCTAssertTrue(signals.contains(.clear))
        }

        // MARK: - Agentive signal

        func test_committedKeyword_returnsAgentive() {
            let signals = self.sut.extractSignals(
                from: "I committed to finishing the project",
                context: .morningThoughts
            )
            XCTAssertTrue(signals.contains(.agentive))
        }

        func test_achievedKeyword_returnsAgentive() {
            let signals = self.sut.extractSignals(from: "I achieved what I set out to do", context: .eveningJournal)
            XCTAssertTrue(signals.contains(.agentive))
        }

        // MARK: - Self-compassionate signal

        func test_gentleKeyword_returnsSelfCompassionate() {
            let signals = self.sut.extractSignals(from: "Being gentle with myself today", context: .eveningJournal)
            XCTAssertTrue(signals.contains(.selfCompassionate))
        }

        func test_selfCareKeyword_returnsSelfCompassionate() {
            let signals = self.sut.extractSignals(
                from: "Took time for self-care this evening",
                context: .eveningJournal
            )
            XCTAssertTrue(signals.contains(.selfCompassionate))
        }

        // MARK: - Mixed signals

        func test_mixedText_canProduceMultipleSignals() {
            let signals = self.sut.extractSignals(
                from: "Grateful yet stressed about deadlines",
                context: .morningThoughts
            )
            XCTAssertTrue(signals.contains(.grateful))
            XCTAssertTrue(signals.contains(.stressed))
        }

        func test_noKeywords_returnsNeutral() {
            let signals = self.sut.extractSignals(from: "Had breakfast and went for a walk", context: .morningThoughts)
            XCTAssertEqual(signals, [.neutral])
        }

        // MARK: - Case insensitivity

        func test_uppercaseKeyword_isRecognised() {
            let signals = self.sut.extractSignals(from: "FEELING GRATEFUL AND HAPPY", context: .morningThoughts)
            XCTAssertTrue(signals.contains(.grateful))
        }

        // MARK: - clarityScore

        func test_clarityScore_returnsValueBetweenZeroAndOne() {
            let score = self.sut.clarityScore(from: "Clear mind, focused on goals")
            XCTAssertGreaterThanOrEqual(score, 0.0)
            XCTAssertLessThanOrEqual(score, 1.0)
        }

        func test_clarityScore_emptyText_returnsHalf() {
            XCTAssertEqual(self.sut.clarityScore(from: ""), 0.5, accuracy: 0.01)
        }

        func test_clarityScore_overwhelmedText_isLowerThanClearText() {
            let overwhelmedScore = self.sut.clarityScore(from: "Overwhelmed, too much to do")
            let clearScore = self.sut.clarityScore(from: "Clear, focused, organized today")
            XCTAssertLessThan(overwhelmedScore, clearScore)
        }

        // MARK: - sentimentScore

        func test_sentimentScore_returnsValueBetweenZeroAndOne() {
            let score = self.sut.sentimentScore(from: "I feel grateful and content")
            XCTAssertGreaterThanOrEqual(score, 0.0)
            XCTAssertLessThanOrEqual(score, 1.0)
        }

        func test_sentimentScore_negativeText_isBelow_positiveText() {
            let negScore = self.sut.sentimentScore(from: "Stressed, anxious, overwhelmed")
            let posScore = self.sut.sentimentScore(from: "Grateful, thankful, joyful")
            XCTAssertLessThan(negScore, posScore)
        }

        // MARK: - Protocol conformance

        func test_extractorConformsToProtocol() {
            let _: any TextSignalExtracting = TextSignalExtractor()
        }
    }

#endif
