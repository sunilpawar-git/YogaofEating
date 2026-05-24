#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Phase 6 TDD: CorrelationCard must optionally carry server-grounding data references.
    /// The iOS side degrades gracefully when references are absent (backward-compatible).
    final class CorrelationCardDataReferencesTests: XCTestCase {
        // MARK: - Model

        // Red: CorrelationCard currently has no dataReferences field
        func test_correlationCard_decodesDataReferences_whenPresent() {
            let json = """
            {
                "id": "12345678-1234-1234-1234-123456789012",
                "category": "foodToSleep",
                "observation": "High-score meals correlate with better sleep",
                "confidence": 0.85,
                "dataPoints": [],
                "dataReferences": ["Monday dinner score: 0.9", "Tuesday dinner score: 0.85"]
            }
            """.data(using: .utf8)!
            let card = try? JSONDecoder().decode(CorrelationCard.self, from: json)
            XCTAssertEqual(card?.dataReferences?.count, 2)
        }

        // Red: when dataReferences is absent, it should be nil (not error)
        func test_correlationCard_decodesSuccessfully_whenDataReferencesAbsent() {
            let json = """
            {
                "id": "12345678-1234-1234-1234-123456789012",
                "category": "foodToSleep",
                "observation": "Some observation",
                "confidence": 0.7,
                "dataPoints": []
            }
            """.data(using: .utf8)!
            let card = try? JSONDecoder().decode(CorrelationCard.self, from: json)
            XCTAssertNotNil(card, "Card without dataReferences must still decode successfully")
            XCTAssertNil(card?.dataReferences)
        }

        // Red: Codable round-trip preserves dataReferences
        func test_correlationCard_roundTrip_preservesDataReferences() throws {
            let card = CorrelationCard(
                category: .foodToSleep,
                observation: "Test observation",
                confidence: 0.8,
                dataReferences: ["Ref A", "Ref B"]
            )
            let data = try JSONEncoder().encode(card)
            let decoded = try JSONDecoder().decode(CorrelationCard.self, from: data)
            XCTAssertEqual(decoded.dataReferences, ["Ref A", "Ref B"])
        }

        // Regression: server response without dataReferences must not break existing parsing
        func test_briefingResponse_decodesCards_withoutDataReferences() {
            let response: [String: Any] = [
                "category": "food",
                "observation": "You eat well on Mondays",
                "confidence": 0.75
            ]
            let catStr = response["category"] as? String ?? ""
            let obs = response["observation"] as? String ?? ""
            let conf = response["confidence"] as? Double ?? 0.5
            let cat = CorrelationCategory(rawValue: catStr) ?? .foodToSleep
            let card = CorrelationCard(category: cat, observation: obs, confidence: conf)
            XCTAssertNil(card.dataReferences, "Cards without server references should have nil dataReferences")
        }
    }

#endif
