import XCTest
@testable import Yoga_of_Eating

/// TDD tests for the .observation MindCheckCategory and its integration
/// into DayModuleProgress (Highlight module).
final class ObservationCategoryTests: XCTestCase {
    // MARK: - Category Properties

    func test_observation_hasCorrectEmoji() {
        XCTAssertEqual(MindCheckCategory.observation.emoji, "👁️")
    }

    func test_observation_hasCorrectDisplayName() {
        XCTAssertEqual(MindCheckCategory.observation.displayName, "Observed")
    }

    func test_observation_isEveningContext() {
        XCTAssertEqual(MindCheckCategory.observation.context, .evening)
    }

    func test_observation_includedInEveningCategories() {
        let evening = MindCheckCategory.categories(for: .evening)
        XCTAssertTrue(evening.contains(.observation))
    }

    func test_observation_notInMorningCategories() {
        let morning = MindCheckCategory.categories(for: .morning)
        XCTAssertFalse(morning.contains(.observation))
    }

    // MARK: - Backward Compatibility

    func test_observation_codable_encodesAndDecodes() throws {
        let entry = MindCheckEntry(
            category: .observation,
            text: "I noticed I eat less when calm",
            context: .evening
        )
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(MindCheckEntry.self, from: data)

        XCTAssertEqual(decoded.category, .observation)
        XCTAssertEqual(decoded.text, "I noticed I eat less when calm")
        XCTAssertEqual(decoded.context, .evening)
    }

    func test_legacyData_withoutObservation_decodesWithoutError() throws {
        let json = """
        {
            "id": "12345678-1234-1234-1234-123456789012",
            "category": "gratefulFor",
            "text": "Family",
            "timestamp": 1000000,
            "context": "evening"
        }
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(MindCheckEntry.self, from: data)
        XCTAssertEqual(decoded.category, .gratefulFor)
    }

    // MARK: - Highlight Progress with Observation

    func test_highlight_withObservation_getsCredit() {
        let reflection = DailyReflection(feeling: .great)
        let observation = MindCheckEntry(
            category: .observation,
            text: "Sugar makes me tired",
            context: .evening
        )
        let gratitude = MindCheckEntry(
            category: .gratefulFor,
            text: "Good weather",
            context: .evening
        )
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.0,
            reflection: reflection,
            eveningMindCheck: [gratitude, observation]
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertEqual(progress.highlightProgress, 1.0, accuracy: 0.01)
    }

    func test_highlight_withoutObservation_partial() {
        let reflection = DailyReflection(feeling: .great)
        let gratitude = MindCheckEntry(
            category: .gratefulFor,
            text: "Good weather",
            context: .evening
        )
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.0,
            reflection: reflection,
            eveningMindCheck: [gratitude]
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertGreaterThan(progress.highlightProgress, 0.5)
        XCTAssertLessThan(progress.highlightProgress, 1.0)
    }
}
