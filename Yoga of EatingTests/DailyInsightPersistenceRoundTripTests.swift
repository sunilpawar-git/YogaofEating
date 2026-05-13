import Foundation
import XCTest
@testable import Yoga_of_Eating

/// Codable round-trip tests for the unified DailyInsight model.
/// Verifies no data loss when encoding to JSON and decoding back.
@MainActor
final class DailyInsightPersistenceRoundTripTests: XCTestCase {
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Round-trip

    func test_encode_decode_roundTrip_preservesAllFields() throws {
        let original = self.makeFullInsight()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(DailyInsight.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.headline, original.headline)
        XCTAssertEqual(decoded.dominantInsight, original.dominantInsight)
        XCTAssertEqual(decoded.confidence, original.confidence, accuracy: 0.001)
        XCTAssertEqual(decoded.isViewed, original.isViewed)
        XCTAssertEqual(decoded.correlationCards.count, original.correlationCards.count)
        XCTAssertEqual(decoded.nudge.suggestion, original.nudge.suggestion)
        XCTAssertEqual(decoded.weeklyTrend?.daysLogged, original.weeklyTrend?.daysLogged)
        XCTAssertEqual(decoded.textSignals, original.textSignals)
        XCTAssertEqual(decoded.causalExplanation, original.causalExplanation)
    }

    func test_encode_decode_roundTrip_withNilOptionals_usesDefaults() throws {
        let minimal = DailyInsight(
            date: Date(),
            headline: Strings.Insight.Headline.steady,
            dimensions: WellbeingDimensions(
                physicalLoad: 0.5,
                emotionalTone: 0.5,
                cognitiveClarity: 0.5,
                behavioralMomentum: 0.5
            ),
            dominantInsight: "Minimal",
            correlationCards: [],
            nudge: ActionableNudge(
                suggestion: Strings.Insight.Nudge.defaultSuggestion,
                reasoning: Strings.Insight.Nudge.defaultReasoning
            ),
            causalExplanation: "",
            textSignals: [],
            confidence: 0.5
        )

        let data = try encoder.encode(minimal)
        let decoded = try decoder.decode(DailyInsight.self, from: data)

        XCTAssertNil(decoded.weeklyTrend)
        XCTAssertFalse(decoded.isViewed)
        XCTAssertTrue(decoded.correlationCards.isEmpty)
    }

    func test_decode_withExtraUnknownKeys_doesNotThrow() throws {
        var json = try encoder.encode(self.makeFullInsight())
        var dict = try JSONSerialization.jsonObject(with: json) as! [String: Any]
        dict["unknownFutureField"] = "someValue"
        json = try JSONSerialization.data(withJSONObject: dict)
        XCTAssertNoThrow(try self.decoder.decode(DailyInsight.self, from: json))
    }

    // MARK: - Helpers

    private func makeFullInsight() -> DailyInsight {
        let card = CorrelationCard(
            category: .foodToSleep,
            observation: "Good food = good sleep",
            confidence: 0.85,
            dataPoints: []
        )
        let trend = WeeklyTrendSnippet(
            averageFoodScore: 0.7,
            averageSleepQuality: 0.65,
            daysLogged: 5,
            trendDirection: .improving
        )
        return DailyInsight(
            date: Date(),
            headline: Strings.Insight.Headline.strong,
            dimensions: WellbeingDimensions(
                physicalLoad: 0.7,
                emotionalTone: 0.8,
                cognitiveClarity: 0.6,
                behavioralMomentum: 0.5
            ),
            dominantInsight: "Your healthy choices are paying off.",
            correlationCards: [card],
            nudge: ActionableNudge(
                suggestion: Strings.Insight.Nudge.defaultSuggestion,
                reasoning: Strings.Insight.Nudge.defaultReasoning
            ),
            weeklyTrend: trend,
            causalExplanation: "Better food → better sleep → better mood",
            textSignals: [.grateful],
            confidence: 0.9
        )
    }
}
