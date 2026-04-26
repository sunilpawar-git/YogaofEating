import XCTest
@testable import Yoga_of_Eating

final class BodyIntelligenceServiceTests: XCTestCase {
    func test_compute_emptyData_returnsLowScore() {
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.0
        )
        let result = BodyIntelligenceService.compute(from: snapshot, sleepData: nil)
        XCTAssertGreaterThanOrEqual(result.value, 0)
        XCTAssertLessThan(result.value, 35)
    }

    func test_compute_fullData_usesAllPillars() {
        let snapshot = DailySmileySnapshot.create(
            date: Date(),
            smileyState: .neutral,
            meals: [Meal(mealType: .lunch, items: ["Salad"], healthScore: 0.9)],
            reflection: DailyReflection(
                feeling: .great,
                sleepQuality: .great,
                morningEnergyLevel: 5,
                dailyIntention: "Stay light",
                focusRating: 3
            ),
            morningMindCheck: [
                MindCheckEntry(category: .todo, text: "Walk", context: .morning, isAccomplished: true)
            ],
            eveningMindCheck: [
                MindCheckEntry(category: .gratefulFor, text: "Family", context: .evening),
                MindCheckEntry(category: .observation, text: "Steady", context: .evening)
            ]
        )
        let sleepData = SleepData(
            sleepDuration: 8 * 3600,
            timeInBed: 8.5 * 3600,
            sleepStart: nil,
            sleepEnd: nil,
            sleepScore: 90
        )
        let result = BodyIntelligenceService.compute(from: snapshot, sleepData: sleepData)
        XCTAssertGreaterThan(result.value, 80)
        XCTAssertEqual(result.sleepContribution, 90, accuracy: 0.01)
    }

    func test_compute_prefersHealthKitSleepScore() {
        let snapshot = DailySmileySnapshot.create(
            date: Date(),
            smileyState: .neutral,
            meals: [],
            reflection: DailyReflection(sleepQuality: .poor)
        )
        let sleepData = SleepData(
            sleepDuration: 7 * 3600,
            timeInBed: 7.5 * 3600,
            sleepStart: nil,
            sleepEnd: nil,
            sleepScore: 88
        )
        let result = BodyIntelligenceService.compute(from: snapshot, sleepData: sleepData)
        XCTAssertEqual(result.sleepContribution, 88, accuracy: 0.01)
    }

    func test_compute_fallsBackToSubjectiveSleep_whenNoHealthKit() {
        let snapshot = DailySmileySnapshot.create(
            date: Date(),
            smileyState: .neutral,
            meals: [],
            reflection: DailyReflection(sleepQuality: .good)
        )
        let result = BodyIntelligenceService.compute(from: snapshot, sleepData: nil)
        XCTAssertEqual(result.sleepContribution, 70, accuracy: 0.01)
    }

    func test_compute_todoCompletion_fromSnapshot() {
        let today = DailySmileySnapshot.create(
            date: Date(),
            smileyState: .neutral,
            meals: [],
            morningMindCheck: [
                MindCheckEntry(category: .todo, text: "A", context: .morning, isAccomplished: true),
                MindCheckEntry(category: .todo, text: "B", context: .morning, isAccomplished: false)
            ]
        )
        let result = BodyIntelligenceService.compute(from: today, sleepData: nil)
        // 1 of 2 todos completed → 50% → 50 contribution
        XCTAssertEqual(result.executionContribution, 50, accuracy: 0.01)
    }

    func test_model_clamps_values_to_zeroToHundred() {
        let score = BodyIntelligenceScore(
            value: 150,
            moduleContribution: -10,
            sleepContribution: 101,
            nutritionContribution: 50,
            executionContribution: 0
        )
        XCTAssertEqual(score.value, 100)
        XCTAssertEqual(score.moduleContribution, 0)
        XCTAssertEqual(score.sleepContribution, 100)
    }
}
