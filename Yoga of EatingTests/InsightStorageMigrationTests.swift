import Foundation
import XCTest
@testable import Yoga_of_Eating

/// Codable migration tests: verifies old disk formats decode into unified DailyInsight.
/// Tests the three migration paths: new format, enrichedInsight key, briefing key.
@MainActor
final class InsightStorageMigrationTests: XCTestCase {
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

    // MARK: - New format (insight key with DailyInsight)

    func test_decode_newFormat_insightKey_loadsCorrectly() throws {
        let original = self.makeSnapshot(insight: self.makeInsight(headline: "New format"))
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(DailySmileySnapshot.self, from: data)
        XCTAssertEqual(decoded.insight?.headline, "New format")
    }

    // MARK: - Migration from enrichedInsight key

    func test_decode_legacyEnrichedInsightKey_migratesIntoInsight() throws {
        // Build JSON that has `enrichedInsight` but no `insight` in new format
        var json = self.buildSnapshotJSON(extraFields: [
            "enrichedInsight": self.buildInsightJSON(headline: "From enriched")
        ])
        let decoded = try decoder.decode(DailySmileySnapshot.self, from: json)
        XCTAssertEqual(decoded.insight?.headline, "From enriched")
    }

    // MARK: - Migration from briefing key

    func test_decode_legacyBriefingKey_migratesIntoInsight() throws {
        let json = self.buildSnapshotJSON(extraFields: [
            "briefing": self.buildBriefingJSON(headline: "From briefing")
        ])
        let decoded = try decoder.decode(DailySmileySnapshot.self, from: json)
        XCTAssertEqual(decoded.insight?.headline, "From briefing")
    }

    // MARK: - No insight data → nil

    func test_decode_noInsightData_insightIsNil() throws {
        let json = self.buildSnapshotJSON(extraFields: [:])
        let decoded = try decoder.decode(DailySmileySnapshot.self, from: json)
        XCTAssertNil(decoded.insight)
    }

    // MARK: - Priority: new format wins over legacy

    func test_decode_bothNewAndEnrichedPresent_newInsightWins() throws {
        let json = self.buildSnapshotJSON(extraFields: [
            "insight": self.buildInsightJSON(headline: "New wins"),
            "enrichedInsight": self.buildInsightJSON(headline: "Old loses")
        ])
        let decoded = try decoder.decode(DailySmileySnapshot.self, from: json)
        XCTAssertEqual(decoded.insight?.headline, "New wins")
    }

    func test_decode_enrichedWinsOverBriefingWhenBothPresent() throws {
        let json = self.buildSnapshotJSON(extraFields: [
            "enrichedInsight": self.buildInsightJSON(headline: "Enriched wins"),
            "briefing": self.buildBriefingJSON(headline: "Briefing loses")
        ])
        let decoded = try decoder.decode(DailySmileySnapshot.self, from: json)
        XCTAssertEqual(decoded.insight?.headline, "Enriched wins")
    }

    // MARK: - Round-trip preserves unified insight

    func test_roundTrip_encodeDecode_preservesInsight() throws {
        let original = self.makeSnapshot(insight: self.makeInsight(headline: "Round trip"))
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(DailySmileySnapshot.self, from: data)
        XCTAssertEqual(decoded.insight?.headline, "Round trip")
        XCTAssertEqual(decoded.insight?.confidence ?? 0, original.insight?.confidence ?? 0, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func makeInsight(headline: String) -> DailyInsight {
        DailyInsight(
            date: Date(),
            headline: headline,
            dimensions: WellbeingDimensions(
                physicalLoad: 0.5,
                emotionalTone: 0.5,
                cognitiveClarity: 0.5,
                behavioralMomentum: 0.5
            ),
            dominantInsight: "Test",
            correlationCards: [],
            nudge: ActionableNudge(
                suggestion: Strings.Insight.Nudge.defaultSuggestion,
                reasoning: Strings.Insight.Nudge.defaultReasoning
            ),
            causalExplanation: "",
            textSignals: [],
            confidence: 0.75
        )
    }

    private func makeSnapshot(insight: DailyInsight? = nil) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.5,
            insight: insight
        )
    }

    private func buildSnapshotJSON(extraFields: [String: Any]) -> Data {
        let formatter = ISO8601DateFormatter()
        var base: [String: Any] = [
            "id": UUID().uuidString,
            "date": formatter.string(from: Date()),
            "smileyState": ["mood": "neutral", "scale": 1.0],
            "meals": [],
            "mealCount": 0,
            "averageHealthScore": 0.5,
            "hasCompleteCalorieData": false
        ]
        for (k, v) in extraFields {
            base[k] = v
        }
        return (try? JSONSerialization.data(withJSONObject: base)) ?? Data()
    }

    private func buildInsightJSON(headline: String) -> [String: Any] {
        let formatter = ISO8601DateFormatter()
        return [
            "id": UUID().uuidString,
            "date": formatter.string(from: Date()),
            "generatedAt": formatter.string(from: Date()),
            "headline": headline,
            "dimensions": [
                "physicalLoad": 0.5,
                "emotionalTone": 0.5,
                "cognitiveClarity": 0.5,
                "behavioralMomentum": 0.5
            ],
            "dominantInsight": "Test",
            "correlationCards": [],
            "nudge": [
                "suggestion": "Test suggestion",
                "reasoning": "Test reasoning"
            ],
            "causalExplanation": "",
            "textSignals": [],
            "confidence": 0.75,
            "isViewed": false
        ]
    }

    private func buildBriefingJSON(headline: String) -> [String: Any] {
        let formatter = ISO8601DateFormatter()
        return [
            "id": UUID().uuidString,
            "date": formatter.string(from: Date()),
            "generatedAt": formatter.string(from: Date()),
            "headline": headline,
            "correlationCards": [],
            "nudge": [
                "suggestion": "Test suggestion",
                "reasoning": "Test reasoning"
            ],
            "isViewed": false
        ]
    }
}
