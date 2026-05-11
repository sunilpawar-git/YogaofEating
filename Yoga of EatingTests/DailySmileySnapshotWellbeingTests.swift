#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class DailySmileySnapshotWellbeingTests: XCTestCase {
        // MARK: - Legacy JSON backward compatibility

        func test_decodesFromLegacyJSON_withoutWellbeingFields() throws {
            let json = """
            {
                "id": "12345678-1234-1234-1234-123456789012",
                "date": 0,
                "smileyState": {"scale": 1.0, "mood": "neutral"},
                "meals": [],
                "mealCount": 0,
                "averageHealthScore": 0.5
            }
            """.data(using: .utf8)!

            let snapshot = try JSONDecoder().decode(DailySmileySnapshot.self, from: json)
            XCTAssertNil(snapshot.wellbeingDimensions)
            XCTAssertNil(snapshot.textSignals)
        }

        func test_decodesFromLegacyJSON_nilFieldsDoNotCrash() throws {
            let json = """
            {
                "id": "12345678-1234-1234-1234-123456789012",
                "date": 1234567890,
                "smileyState": {"scale": 1.2, "mood": "serene"},
                "meals": [],
                "mealCount": 0,
                "averageHealthScore": 0.75,
                "reflection": null,
                "highlightData": null
            }
            """.data(using: .utf8)!

            let snapshot = try JSONDecoder().decode(DailySmileySnapshot.self, from: json)
            XCTAssertNil(snapshot.wellbeingDimensions)
            XCTAssertNil(snapshot.textSignals)
        }

        // MARK: - withWellbeingDimensions updater

        func test_withWellbeingDimensions_returnsNewCopyWithDimensions() {
            let original = DailySmileySnapshotBuilder().build()
            let dimensions = WellbeingDimensions(
                physicalLoad: 0.7,
                emotionalTone: 0.6,
                cognitiveClarity: 0.8,
                behavioralMomentum: 0.5
            )

            let updated = original.withWellbeingDimensions(dimensions)

            XCTAssertEqual(updated.wellbeingDimensions, dimensions)
        }

        func test_withWellbeingDimensions_doesNotMutateOriginal() {
            let original = DailySmileySnapshotBuilder().build()
            let dimensions = WellbeingDimensions.neutral

            _ = original.withWellbeingDimensions(dimensions)

            XCTAssertNil(original.wellbeingDimensions)
        }

        func test_withWellbeingDimensions_preservesExistingFields() {
            let meals = [MealBuilder().withItems(["salad"]).withScore(0.8).build()]
            let original = DailySmileySnapshotBuilder().withMeals(meals).build()
            let dimensions = WellbeingDimensions.neutral

            let updated = original.withWellbeingDimensions(dimensions)

            XCTAssertEqual(updated.meals.count, 1)
            XCTAssertEqual(updated.averageHealthScore, original.averageHealthScore, accuracy: 0.001)
        }

        // MARK: - withTextSignals updater

        func test_withTextSignals_returnsNewCopyWithSignals() {
            let original = DailySmileySnapshotBuilder().build()
            let signals: [TextSignal] = [.grateful, .clear]

            let updated = original.withTextSignals(signals)

            XCTAssertEqual(updated.textSignals, signals)
        }

        func test_withTextSignals_doesNotMutateOriginal() {
            let original = DailySmileySnapshotBuilder().build()

            _ = original.withTextSignals([.stressed])

            XCTAssertNil(original.textSignals)
        }

        func test_withTextSignals_emptyArray_isPersisted() {
            let original = DailySmileySnapshotBuilder().build()
            let updated = original.withTextSignals([])
            XCTAssertEqual(updated.textSignals, [])
        }

        // MARK: - Codable round-trip with new fields

        func test_codableRoundTrip_withWellbeingDimensions() throws {
            let dimensions = WellbeingDimensions(
                physicalLoad: 0.7,
                emotionalTone: 0.6,
                cognitiveClarity: 0.8,
                behavioralMomentum: 0.55
            )
            let original = DailySmileySnapshotBuilder()
                .withWellbeingDimensions(dimensions)
                .build()

            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(DailySmileySnapshot.self, from: data)

            XCTAssertEqual(decoded.wellbeingDimensions, dimensions)
        }

        func test_codableRoundTrip_withTextSignals() throws {
            let signals: [TextSignal] = [.grateful, .clear, .stressed]
            let original = DailySmileySnapshotBuilder()
                .withTextSignals(signals)
                .build()

            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(DailySmileySnapshot.self, from: data)

            XCTAssertEqual(decoded.textSignals, signals)
        }

        func test_codableRoundTrip_withBothFields_preservesAll() throws {
            let dimensions = WellbeingDimensions.neutral
            let signals: [TextSignal] = [.agentive, .selfCompassionate]
            let original = DailySmileySnapshotBuilder()
                .withWellbeingDimensions(dimensions)
                .withTextSignals(signals)
                .build()

            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(DailySmileySnapshot.self, from: data)

            XCTAssertEqual(decoded.wellbeingDimensions, dimensions)
            XCTAssertEqual(decoded.textSignals, signals)
        }
    }

#endif
