import XCTest
@testable import Yoga_of_Eating

/// Phase 4 — TDD Red tests for TestBuilders.
///
/// These tests are written FIRST and will fail until TestBuilders.swift is created (Red → Green cycle).
/// Each test validates ONE builder behaviour: defaults, chaining, or uniqueness.
@MainActor
final class BuilderTests: XCTestCase {
    // MARK: - MealBuilder defaults

    func test_mealBuilder_build_hasExpectedDefaults() {
        let meal = MealBuilder().build()
        XCTAssertEqual(meal.items, ["test meal"])
        XCTAssertEqual(meal.healthScore, 0.5, accuracy: 0.001)
        XCTAssertFalse(meal.isAIAnalyzed)
        XCTAssertNil(meal.aiInsight)
    }

    func test_mealBuilder_withItems_setsItems() {
        let meal = MealBuilder().withItems(["salad", "water"]).build()
        XCTAssertEqual(meal.items, ["salad", "water"])
    }

    func test_mealBuilder_withScore_setsHealthScore() {
        let meal = MealBuilder().withScore(0.8).build()
        XCTAssertEqual(meal.healthScore, 0.8, accuracy: 0.001)
    }

    func test_mealBuilder_analyzed_setsIsAIAnalyzed() {
        let meal = MealBuilder().analyzed().build()
        XCTAssertTrue(meal.isAIAnalyzed)
    }

    func test_mealBuilder_withInsight_setsAIInsight() {
        let meal = MealBuilder().withInsight("Eat more greens.").build()
        XCTAssertEqual(meal.aiInsight, "Eat more greens.")
    }

    func test_mealBuilder_withMealType_setsMealType() {
        let meal = MealBuilder().withMealType(.dinner).build()
        XCTAssertEqual(meal.mealType, .dinner)
    }

    func test_mealBuilder_chaining_combinesAllProperties() {
        let meal = MealBuilder()
            .withItems(["pizza"])
            .withScore(0.2)
            .analyzed()
            .withInsight("Too much fat.")
            .withMealType(.lunch)
            .build()

        XCTAssertEqual(meal.items, ["pizza"])
        XCTAssertEqual(meal.healthScore, 0.2, accuracy: 0.001)
        XCTAssertTrue(meal.isAIAnalyzed)
        XCTAssertEqual(meal.aiInsight, "Too much fat.")
        XCTAssertEqual(meal.mealType, .lunch)
    }

    func test_mealBuilder_build_producesUniqueIDs() {
        let id1 = MealBuilder().build().id
        let id2 = MealBuilder().build().id
        XCTAssertNotEqual(id1, id2)
    }

    // MARK: - DailySmileySnapshotBuilder defaults

    func test_snapshotBuilder_build_hasExpectedDefaults() {
        let snapshot = DailySmileySnapshotBuilder().build()
        XCTAssertEqual(snapshot.smileyState.mood, .neutral)
        XCTAssertTrue(snapshot.meals.isEmpty)
        XCTAssertNil(snapshot.reflection)
        XCTAssertNil(snapshot.morningMindCheck)
        XCTAssertNil(snapshot.eveningMindCheck)
        XCTAssertNil(snapshot.insight)
    }

    func test_snapshotBuilder_withMeals_setsMeals() {
        let meals = [MealBuilder().withItems(["oats"]).build()]
        let snapshot = DailySmileySnapshotBuilder().withMeals(meals).build()
        XCTAssertEqual(snapshot.meals.count, 1)
        XCTAssertEqual(snapshot.meals.first?.items, ["oats"])
    }

    func test_snapshotBuilder_withSmileyState_setSmileyState() {
        let state = SmileyState(scale: 1.2, mood: .serene)
        let snapshot = DailySmileySnapshotBuilder().withSmileyState(state).build()
        XCTAssertEqual(snapshot.smileyState.mood, .serene)
        XCTAssertEqual(snapshot.smileyState.scale, 1.2, accuracy: 0.001)
    }

    func test_snapshotBuilder_withDate_normalizesToMidnight() {
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let snapshot = DailySmileySnapshotBuilder().withDate(noon).build()
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: snapshot.date)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func test_snapshotBuilder_withInsight_setsInsight() {
        let insight = DailyInsightBuilder().build()
        let snapshot = DailySmileySnapshotBuilder().withInsight(insight).build()
        XCTAssertNotNil(snapshot.insight)
    }

    func test_snapshotBuilder_build_producesUniqueIDs() {
        let id1 = DailySmileySnapshotBuilder().build().id
        let id2 = DailySmileySnapshotBuilder().build().id
        XCTAssertNotEqual(id1, id2)
    }

    func test_snapshotBuilder_withDaysAgo_setsCorrectDate() {
        let snapshot = DailySmileySnapshotBuilder().daysAgo(3).build()
        let diff = Calendar.current.dateComponents([.day], from: snapshot.date, to: Date()).day ?? 0
        XCTAssertEqual(diff, 3)
    }

    // MARK: - MindCheckEntryBuilder defaults

    func test_mindCheckEntryBuilder_build_hasExpectedDefaults() {
        let entry = MindCheckEntryBuilder().build()
        XCTAssertEqual(entry.category, .todo)
        XCTAssertEqual(entry.context, .morning)
        XCTAssertFalse(entry.text.isEmpty)
        XCTAssertNil(entry.isAccomplished)
        XCTAssertEqual(entry.carriedOverCount, 0)
    }

    func test_mindCheckEntryBuilder_withCategory_setsCategory() {
        let entry = MindCheckEntryBuilder().withCategory(.accomplished).build()
        XCTAssertEqual(entry.category, .accomplished)
    }

    func test_mindCheckEntryBuilder_withText_setsText() {
        let entry = MindCheckEntryBuilder().withText("Walk 10k steps").build()
        XCTAssertEqual(entry.text, "Walk 10k steps")
    }

    func test_mindCheckEntryBuilder_accomplished_setsIsAccomplished() {
        let entry = MindCheckEntryBuilder().accomplished().build()
        XCTAssertEqual(entry.isAccomplished, true)
    }

    func test_mindCheckEntryBuilder_build_producesUniqueIDs() {
        let id1 = MindCheckEntryBuilder().build().id
        let id2 = MindCheckEntryBuilder().build().id
        XCTAssertNotEqual(id1, id2)
    }

    // MARK: - DailyInsightBuilder defaults

    func test_dailyInsightBuilder_build_hasExpectedDefaults() {
        let insight = DailyInsightBuilder().build()
        XCTAssertFalse(insight.insightText.isEmpty)
        XCTAssertEqual(insight.insightType, .encouragement)
        XCTAssertGreaterThan(insight.confidence, 0.0)
        XCTAssertFalse(insight.isViewed)
        XCTAssertTrue(insight.references.isEmpty)
    }

    func test_dailyInsightBuilder_withText_setsInsightText() {
        let insight = DailyInsightBuilder().withText("You slept better after lighter dinners.").build()
        XCTAssertEqual(insight.insightText, "You slept better after lighter dinners.")
    }

    func test_dailyInsightBuilder_withType_setsInsightType() {
        let insight = DailyInsightBuilder().withType(.foodSleep).build()
        XCTAssertEqual(insight.insightType, .foodSleep)
    }

    func test_dailyInsightBuilder_viewed_setsIsViewed() {
        let insight = DailyInsightBuilder().viewed().build()
        XCTAssertTrue(insight.isViewed)
    }

    func test_dailyInsightBuilder_build_producesUniqueIDs() {
        let id1 = DailyInsightBuilder().build().id
        let id2 = DailyInsightBuilder().build().id
        XCTAssertNotEqual(id1, id2)
    }

    // MARK: - HealthProfileBuilder defaults

    func test_healthProfileBuilder_build_hasExpectedDefaults() {
        let profile = HealthProfileBuilder().build()
        XCTAssertGreaterThan(profile.age, 0)
        XCTAssertGreaterThan(profile.bmi, 0)
        XCTAssertGreaterThan(profile.bmr, 0)
        XCTAssertGreaterThan(profile.tdee, 0)
        XCTAssertGreaterThanOrEqual(profile.sensitivityMultiplier, 0.5)
        XCTAssertLessThanOrEqual(profile.sensitivityMultiplier, 1.5)
    }

    func test_healthProfileBuilder_withAge_setsAge() {
        let profile = HealthProfileBuilder().withAge(30).build()
        XCTAssertEqual(profile.age, 30)
    }

    func test_healthProfileBuilder_withBMI_setsBMIAndCategory() {
        let profile = HealthProfileBuilder().withBMI(22.5).build()
        XCTAssertEqual(profile.bmi, 22.5, accuracy: 0.001)
        XCTAssertEqual(profile.bmiCategory, .normal)
    }

    func test_healthProfileBuilder_withRiskLevel_setsRiskLevel() {
        let profile = HealthProfileBuilder().withRiskLevel(.high).build()
        XCTAssertEqual(profile.riskLevel, .high)
    }

    // MARK: - Migration test: refactor pattern matches builder output

    func test_mealBuilder_migration_matchesInlineConstruction() {
        let fixedID = UUID()
        let fixedDate = Date(timeIntervalSinceReferenceDate: 1_000_000)

        let inline = Meal(
            id: fixedID,
            timestamp: fixedDate,
            mealType: .lunch,
            items: ["salad"],
            healthScore: 0.5,
            isAIAnalyzed: false,
            aiInsight: nil
        )

        let built = MealBuilder()
            .withID(fixedID)
            .withTimestamp(fixedDate)
            .withMealType(.lunch)
            .withItems(["salad"])
            .withScore(0.5)
            .build()

        XCTAssertEqual(inline, built)
    }
}
