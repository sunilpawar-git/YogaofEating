import XCTest
@testable import Yoga_of_Eating

/// TDD tests for DayModuleProgress — the data backbone of the Day Ring.
/// Tests computation of per-module completion from DailySmileySnapshot data.
final class DayModuleProgressTests: XCTestCase {
    // MARK: - Empty Snapshot

    func test_emptySnapshot_allProgressZero() {
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.0
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertEqual(progress.reflectProgress, 0.0, accuracy: 0.01)
        XCTAssertEqual(progress.laserProgress, 0.0, accuracy: 0.01)
        XCTAssertEqual(progress.highlightProgress, 0.0, accuracy: 0.01)
        XCTAssertEqual(progress.energiseProgress, 0.0, accuracy: 0.01)
        XCTAssertEqual(progress.overallProgress, 0.0, accuracy: 0.01)
    }

    // MARK: - Reflect Module

    func test_reflect_sleepQualityOnly_partialProgress() {
        let reflection = DailyReflection(sleepQuality: .good)
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.0,
            reflection: reflection
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertGreaterThan(progress.reflectProgress, 0.0)
        XCTAssertLessThan(progress.reflectProgress, 1.0)
    }

    func test_reflect_energyAndIntentionOnly_partialProgress() {
        let reflection = DailyReflection(
            morningEnergyLevel: 4,
            dailyIntention: "Stay light"
        )
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.0,
            reflection: reflection
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertGreaterThan(progress.reflectProgress, 0.0)
        XCTAssertLessThan(progress.reflectProgress, 1.0)
    }

    func test_reflect_allFieldsSet_fullProgress() {
        let reflection = DailyReflection(
            sleepQuality: .great,
            morningEnergyLevel: 5,
            dailyIntention: "Focus on protein"
        )
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.0,
            reflection: reflection
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertEqual(progress.reflectProgress, 1.0, accuracy: 0.01)
    }

    // MARK: - Laser Module

    func test_laser_mealsOnly_partialProgress() {
        let meal = Meal(mealType: .lunch, items: ["Salad"], healthScore: 0.8)
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [meal],
            mealCount: 1,
            averageHealthScore: 0.8
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertGreaterThan(progress.laserProgress, 0.0)
        XCTAssertLessThan(progress.laserProgress, 1.0)
    }

    func test_laser_mealsAndReviewedTodos_partialWithoutFocus() {
        let meal = Meal(mealType: .lunch, items: ["Salad"], healthScore: 0.8)
        let todo = MindCheckEntry(
            category: .todo,
            text: "Exercise",
            context: .morning,
            isAccomplished: true
        )
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [meal],
            mealCount: 1,
            averageHealthScore: 0.8,
            morningMindCheck: [todo]
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertGreaterThan(progress.laserProgress, 0.5)
        XCTAssertLessThan(progress.laserProgress, 1.0)
    }

    func test_laser_allThreeSignals_fullProgress() {
        let meal = Meal(mealType: .lunch, items: ["Salad"], healthScore: 0.8)
        let todo = MindCheckEntry(
            category: .todo,
            text: "Exercise",
            context: .morning,
            isAccomplished: true
        )
        let reflection = DailyReflection(focusRating: 3)
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [meal],
            mealCount: 1,
            averageHealthScore: 0.8,
            reflection: reflection,
            morningMindCheck: [todo]
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertEqual(progress.laserProgress, 1.0, accuracy: 0.01)
    }

    func test_laser_todosNotReviewed_noTodoCredit() {
        let meal = Meal(mealType: .lunch, items: ["Salad"], healthScore: 0.8)
        let todo = MindCheckEntry(
            category: .todo,
            text: "Exercise",
            context: .morning,
            isAccomplished: nil
        )
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [meal],
            mealCount: 1,
            averageHealthScore: 0.8,
            morningMindCheck: [todo]
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertGreaterThan(progress.laserProgress, 0.0)
        XCTAssertLessThan(progress.laserProgress, 1.0)
    }

    // MARK: - Highlight Module

    func test_highlight_feelingOnly_partialProgress() {
        let reflection = DailyReflection(feeling: .calm)
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.0,
            reflection: reflection
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertGreaterThan(progress.highlightProgress, 0.0)
        XCTAssertLessThan(progress.highlightProgress, 1.0)
    }

    func test_highlight_feelingAndEveningEntries_partialWithoutObservation() {
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

    func test_highlight_allThreeSignals_fullProgress() {
        let reflection = DailyReflection(feeling: .great)
        let gratitude = MindCheckEntry(
            category: .gratefulFor,
            text: "Good weather",
            context: .evening
        )
        let observation = MindCheckEntry(
            category: .observation,
            text: "Noticed sugar crash",
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

    // MARK: - Energise Module

    func test_energise_sleepQualityOnly_partialProgress() {
        let reflection = DailyReflection(sleepQuality: .good)
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.0,
            reflection: reflection
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertGreaterThan(progress.energiseProgress, 0.0)
        XCTAssertLessThan(progress.energiseProgress, 1.0)
    }

    func test_energise_sleepAndMeals_fullProgress() {
        let reflection = DailyReflection(sleepQuality: .great)
        let meal = Meal(mealType: .lunch, items: ["Rice"], healthScore: 0.6)
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [meal],
            mealCount: 1,
            averageHealthScore: 0.6,
            reflection: reflection
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertEqual(progress.energiseProgress, 1.0, accuracy: 0.01)
    }

    // MARK: - Overall Progress

    func test_overallProgress_isAverageOfModules() {
        let reflection = DailyReflection(
            feeling: .great,
            sleepQuality: .great,
            morningEnergyLevel: 5,
            dailyIntention: "Stay focused",
            focusRating: 2
        )
        let meal = Meal(mealType: .lunch, items: ["Rice"], healthScore: 0.6)
        let todo = MindCheckEntry(
            category: .todo,
            text: "Walk",
            context: .morning,
            isAccomplished: true
        )
        let gratitude = MindCheckEntry(
            category: .gratefulFor,
            text: "Family",
            context: .evening
        )
        let observation = MindCheckEntry(
            category: .observation,
            text: "Less hungry today",
            context: .evening
        )
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [meal],
            mealCount: 1,
            averageHealthScore: 0.6,
            reflection: reflection,
            morningMindCheck: [todo],
            eveningMindCheck: [gratitude, observation]
        )
        let progress = DayModuleProgress.compute(from: snapshot)
        let expected = (
            progress.reflectProgress +
                progress.laserProgress +
                progress.highlightProgress +
                progress.energiseProgress
        ) / 4.0

        XCTAssertEqual(progress.overallProgress, expected, accuracy: 0.01)
    }

    func test_fullyCompleteDay_allModulesAt100() {
        let reflection = DailyReflection(
            feeling: .great,
            sleepQuality: .great,
            morningEnergyLevel: 5,
            dailyIntention: "Stay focused",
            focusRating: 3
        )
        let meal = Meal(mealType: .lunch, items: ["Rice"], healthScore: 0.6)
        let todo = MindCheckEntry(
            category: .todo,
            text: "Walk",
            context: .morning,
            isAccomplished: true
        )
        let gratitude = MindCheckEntry(
            category: .gratefulFor,
            text: "Family",
            context: .evening
        )
        let observation = MindCheckEntry(
            category: .observation,
            text: "Noticed lighter feeling",
            context: .evening
        )
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [meal],
            mealCount: 1,
            averageHealthScore: 0.6,
            reflection: reflection,
            morningMindCheck: [todo],
            eveningMindCheck: [gratitude, observation]
        )
        let progress = DayModuleProgress.compute(from: snapshot)

        XCTAssertEqual(progress.reflectProgress, 1.0, accuracy: 0.01)
        XCTAssertEqual(progress.laserProgress, 1.0, accuracy: 0.01)
        XCTAssertEqual(progress.highlightProgress, 1.0, accuracy: 0.01)
        XCTAssertEqual(progress.energiseProgress, 1.0, accuracy: 0.01)
        XCTAssertEqual(progress.overallProgress, 1.0, accuracy: 0.01)
    }

    // MARK: - Equatable

    func test_equatable_sameValues_areEqual() {
        let progressA = DayModuleProgress(
            reflectProgress: 0.5,
            laserProgress: 0.3,
            highlightProgress: 0.7,
            energiseProgress: 1.0
        )
        let progressB = DayModuleProgress(
            reflectProgress: 0.5,
            laserProgress: 0.3,
            highlightProgress: 0.7,
            energiseProgress: 1.0
        )
        XCTAssertEqual(progressA, progressB)
    }

    // MARK: - Clamping

    func test_progressValues_areClamped_zeroToOne() {
        let progress = DayModuleProgress(
            reflectProgress: -0.5,
            laserProgress: 1.5,
            highlightProgress: 0.5,
            energiseProgress: 0.0
        )
        XCTAssertGreaterThanOrEqual(progress.reflectProgress, 0.0)
        XCTAssertLessThanOrEqual(progress.laserProgress, 1.0)
    }
}
