import XCTest

@testable import Yoga_of_Eating

final class WellbeingBreakdownCoachHeaderTests: XCTestCase {
    // MARK: - Progress Text — no pill at top state

    func test_progressText_serene_returnsNil() {
        XCTAssertNil(WellbeingProgressCalculator.progressText(mood: .serene, overall: 0.8))
    }

    func test_progressText_serene_atExactThreshold_returnsNil() {
        XCTAssertNil(WellbeingProgressCalculator.progressText(mood: .serene, overall: 0.65))
    }

    // MARK: - Progress Text — neutral state

    func test_progressText_neutral_score060_returns5pts() {
        let text = WellbeingProgressCalculator.progressText(mood: .neutral, overall: 0.60)
        XCTAssertNotNil(text)
        // (0.65 - 0.60) * 100 = 5 pts
        XCTAssertTrue(text?.contains("5") == true, "Expected '5 pts', got: \(text ?? "nil")")
    }

    func test_progressText_neutral_containsSereneLabel() {
        let text = WellbeingProgressCalculator.progressText(mood: .neutral, overall: 0.55)
        XCTAssertTrue(
            text?.contains(SmileyMood.serene.displayName) == true,
            "Progress text must name the next state"
        )
    }

    func test_progressText_neutral_containsSereneEmoji() {
        let text = WellbeingProgressCalculator.progressText(mood: .neutral, overall: 0.55)
        XCTAssertTrue(
            text?.contains(SmileyMood.serene.emoji) == true,
            "Progress text must include the next state emoji"
        )
    }

    func test_progressText_neutral_score050_returns15pts() {
        let text = WellbeingProgressCalculator.progressText(mood: .neutral, overall: 0.50)
        // (0.65 - 0.50) * 100 = 15 pts
        XCTAssertTrue(text?.contains("15") == true, "Expected '15 pts', got: \(text ?? "nil")")
    }

    // MARK: - Progress Text — thoughtful state

    func test_progressText_thoughtful_score040_returns5pts() {
        let text = WellbeingProgressCalculator.progressText(mood: .thoughtful, overall: 0.40)
        XCTAssertNotNil(text)
        // (0.45 - 0.40) * 100 = 5 pts
        XCTAssertTrue(text?.contains("5") == true, "Expected '5 pts', got: \(text ?? "nil")")
    }

    func test_progressText_thoughtful_containsNeutralLabel() {
        let text = WellbeingProgressCalculator.progressText(mood: .thoughtful, overall: 0.38)
        XCTAssertTrue(
            text?.contains(SmileyMood.neutral.displayName) == true,
            "Progress text must name the next state (Neutral)"
        )
    }

    // MARK: - Progress Text — overwhelmed state

    func test_progressText_overwhelmed_score020_returns15pts() {
        let text = WellbeingProgressCalculator.progressText(mood: .overwhelmed, overall: 0.20)
        XCTAssertNotNil(text)
        // (0.35 - 0.20) * 100 = 15 pts
        XCTAssertTrue(text?.contains("15") == true, "Expected '15 pts', got: \(text ?? "nil")")
    }

    func test_progressText_overwhelmed_containsThoughtfulLabel() {
        let text = WellbeingProgressCalculator.progressText(mood: .overwhelmed, overall: 0.20)
        XCTAssertTrue(
            text?.contains(SmileyMood.thoughtful.displayName) == true,
            "Progress text must name the next state (Thoughtful)"
        )
    }

    // MARK: - Progress Text — concerned treated like overwhelmed

    func test_progressText_concerned_treatedLikeOverwhelmed() {
        let concerned = WellbeingProgressCalculator.progressText(mood: .concerned, overall: 0.20)
        let overwhelmed = WellbeingProgressCalculator.progressText(mood: .overwhelmed, overall: 0.20)
        XCTAssertEqual(concerned, overwhelmed, "Concerned and Overwhelmed must produce the same progress text")
    }

    // MARK: - Format string uses SSOT thresholds (no magic numbers in calculator)

    func test_progressText_neutral_roundsUp() {
        // 0.641 → 64%, threshold 65% → pts = 1
        let text = WellbeingProgressCalculator.progressText(mood: .neutral, overall: 0.641)
        XCTAssertTrue(text?.contains("1") == true, "Sub-threshold fractions should show at least 1 pt")
    }

    func test_progressText_overwhelmed_score034_returns1pt() {
        // (0.35 - 0.34) * 100 = 1 pt
        let text = WellbeingProgressCalculator.progressText(mood: .overwhelmed, overall: 0.34)
        XCTAssertTrue(text?.contains("1") == true, "Expected '1 pt', got: \(text ?? "nil")")
    }
}
