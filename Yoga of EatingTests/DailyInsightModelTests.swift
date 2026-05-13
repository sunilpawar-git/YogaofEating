import Foundation
import XCTest
@testable import Yoga_of_Eating

/// Tests for the unified DailyInsight model (Phase 1 — SSOT model definition).
/// All tests must be written BEFORE any production code compiles (TDD Red phase).
@MainActor
final class DailyInsightModelTests: XCTestCase {
    // MARK: - Field Completeness

    func test_dailyInsight_hasRequiredFields() {
        let insight = DailyInsight(
            date: Date(),
            headline: Strings.Insight.Headline.strong,
            dimensions: WellbeingDimensions(
                physicalLoad: 0.7,
                emotionalTone: 0.8,
                cognitiveClarity: 0.6,
                behavioralMomentum: 0.5
            ),
            dominantInsight: "Test insight text",
            correlationCards: [],
            nudge: ActionableNudge(
                suggestion: Strings.Insight.Nudge.defaultSuggestion,
                reasoning: Strings.Insight.Nudge.defaultReasoning
            ),
            causalExplanation: "Test explanation",
            textSignals: [.grateful],
            confidence: 0.8
        )

        XCTAssertFalse(insight.id.uuidString.isEmpty)
        XCTAssertEqual(insight.headline, Strings.Insight.Headline.strong)
        XCTAssertEqual(insight.dominantInsight, "Test insight text")
        XCTAssertEqual(insight.confidence, 0.8)
        XCTAssertFalse(insight.isViewed)
    }

    // MARK: - Confidence Clamping

    func test_dailyInsight_confidence_clampedToOne_whenAbove() {
        let insight = self.makeInsight(confidence: 1.5)
        XCTAssertEqual(insight.confidence, 1.0)
    }

    func test_dailyInsight_confidence_clampedToZero_whenBelow() {
        let insight = self.makeInsight(confidence: -0.3)
        XCTAssertEqual(insight.confidence, 0.0)
    }

    func test_dailyInsight_confidence_preserved_whenInRange() {
        let insight = self.makeInsight(confidence: 0.72)
        XCTAssertEqual(insight.confidence, 0.72, accuracy: 0.001)
    }

    // MARK: - markAsViewed

    func test_dailyInsight_markAsViewed_setsFlag() {
        var insight = self.makeInsight()
        XCTAssertFalse(insight.isViewed)
        insight.markAsViewed()
        XCTAssertTrue(insight.isViewed)
    }

    func test_dailyInsight_markAsViewed_isIdempotent() {
        var insight = self.makeInsight()
        insight.markAsViewed()
        insight.markAsViewed()
        XCTAssertTrue(insight.isViewed)
    }

    // MARK: - hasCorrelations

    func test_dailyInsight_hasCorrelations_falseWhenEmpty() {
        let insight = self.makeInsight(cards: [])
        XCTAssertFalse(insight.hasCorrelations)
    }

    func test_dailyInsight_hasCorrelations_trueWhenNonEmpty() {
        let card = CorrelationCard(category: .foodToMood, observation: "Test", confidence: 0.7)
        let insight = self.makeInsight(cards: [card])
        XCTAssertTrue(insight.hasCorrelations)
    }

    // MARK: - topCorrelation

    func test_dailyInsight_topCorrelation_nilWhenNoCards() {
        let insight = self.makeInsight(cards: [])
        XCTAssertNil(insight.topCorrelation)
    }

    func test_dailyInsight_topCorrelation_returnsHighestConfidence() {
        let low = CorrelationCard(category: .foodToMood, observation: "Low", confidence: 0.4)
        let high = CorrelationCard(category: .foodToSleep, observation: "High", confidence: 0.9)
        let insight = self.makeInsight(cards: [low, high])
        XCTAssertEqual(insight.topCorrelation?.confidence, 0.9)
    }

    // MARK: - Equatable

    func test_dailyInsight_equalToItself() {
        let insight = self.makeInsight()
        XCTAssertEqual(insight, insight)
    }

    func test_dailyInsight_notEqualWhenIdDiffers() {
        let a = self.makeInsight()
        let b = self.makeInsight()
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Helpers

    private func makeInsight(
        confidence: Double = 0.75,
        cards: [CorrelationCard] = []
    ) -> DailyInsight {
        DailyInsight(
            date: Date(),
            headline: Strings.Insight.Headline.steady,
            dimensions: WellbeingDimensions(
                physicalLoad: 0.5,
                emotionalTone: 0.5,
                cognitiveClarity: 0.5,
                behavioralMomentum: 0.5
            ),
            dominantInsight: "Test",
            correlationCards: cards,
            nudge: ActionableNudge(
                suggestion: Strings.Insight.Nudge.defaultSuggestion,
                reasoning: Strings.Insight.Nudge.defaultReasoning
            ),
            causalExplanation: "Explanation",
            textSignals: [],
            confidence: confidence
        )
    }
}
