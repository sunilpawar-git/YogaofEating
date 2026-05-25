import Foundation
import XCTest
@testable import Yoga_of_Eating

/// Tests for SnapshotPayloadBuilder — the single Firebase payload serialiser.
/// Replaces duplicated payload building in InsightServerFetcher + BriefingService.
@MainActor
final class SnapshotPayloadBuilderTests: XCTestCase {
    // MARK: - Core payload fields

    func test_buildPayload_includesDayName_healthScore_isToday() {
        let today = Calendar.current.startOfDay(for: Date())
        let snap = DailySmileySnapshotBuilder().withDate(today).build()
        let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: today)
        XCTAssertEqual(payload.count, 1)
        XCTAssertNotNil(payload[0]["date"])
        XCTAssertNotNil(payload[0]["averageHealthScore"])
        XCTAssertEqual(payload[0]["isToday"] as? Bool, true)
    }

    func test_buildPayload_includesMeals_whenPresent() {
        let today = Calendar.current.startOfDay(for: Date())
        let meal = MealBuilder().withItems(["Oatmeal", "Banana"]).withScore(0.8).build()
        let snap = DailySmileySnapshotBuilder().withDate(today).withMeals([meal]).build()
        let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: today)
        XCTAssertNotNil(payload[0]["meals"])
    }

    func test_buildPayload_omitsMeals_whenEmpty() {
        let today = Calendar.current.startOfDay(for: Date())
        let snap = DailySmileySnapshotBuilder().withDate(today).build()
        let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: today)
        XCTAssertNil(payload[0]["meals"])
    }

    func test_buildPayload_includesSleepQuality_whenReflectionPresent() {
        let today = Calendar.current.startOfDay(for: Date())
        let reflection = DailyReflection(feeling: .calm, sleepQuality: .great, note: "")
        let snap = DailySmileySnapshotBuilder().withDate(today).withReflection(reflection).build()
        let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: today)
        XCTAssertNotNil(payload[0]["sleepQuality"])
    }

    func test_buildPayload_includesAppleSleepData_whenPresent() {
        let today = Calendar.current.startOfDay(for: Date())
        let snap = DailySmileySnapshotBuilder().withDate(today).build()
        let sleepData = SleepData(
            sleepDuration: 28800,
            timeInBed: 30000,
            sleepStart: nil,
            sleepEnd: nil,
            sleepScore: 85
        )
        let payload = SnapshotPayloadBuilder.build(
            from: [snap],
            healthKitSleepData: [today: sleepData],
            relativeTo: today
        )
        XCTAssertNotNil(payload[0]["appleSleepData"])
        let apple = payload[0]["appleSleepData"] as? [String: Any]
        XCTAssertNotNil(apple?["durationHours"])
        XCTAssertNotNil(apple?["score"])
    }

    func test_buildPayload_includesMorningMindCheck_whenPresent() {
        let today = Calendar.current.startOfDay(for: Date())
        let entry = MindCheckEntry(category: .todo, text: "Exercise", timestamp: today, context: .morning)
        let snap = DailySmileySnapshotBuilder().withDate(today).withMorningMindCheck([entry]).build()
        let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: today)
        XCTAssertNotNil(payload[0]["morningMindCheck"])
    }

    func test_buildPayload_multipleSnapshots_isToday_onlyForMatchingDate() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let snapToday = DailySmileySnapshotBuilder().withDate(today).build()
        let snapYesterday = DailySmileySnapshotBuilder().withDate(yesterday).build()
        let payload = SnapshotPayloadBuilder.build(
            from: [snapToday, snapYesterday],
            healthKitSleepData: [:],
            relativeTo: today
        )
        XCTAssertEqual(payload.count, 2)
        XCTAssertEqual(payload[0]["isToday"] as? Bool, true)
        XCTAssertEqual(payload[1]["isToday"] as? Bool, false)
    }

    // MARK: - mindCheckEntryPayload

    func test_mindCheckEntryPayload_includesTextAndCategory() {
        let entry = MindCheckEntry(
            category: .gratitude,
            text: "Grateful for sunshine",
            timestamp: Date(),
            context: .morning
        )
        let dict = SnapshotPayloadBuilder.mindCheckEntryPayload(entry)
        XCTAssertEqual(dict["text"] as? String, "Grateful for sunshine")
        XCTAssertNotNil(dict["category"])
    }

    func test_mindCheckEntryPayload_todo_includesIsAccomplished() {
        let entry = MindCheckEntry(
            category: .todo,
            text: "Run 5km",
            timestamp: Date(),
            context: .morning,
            isAccomplished: true
        )
        let dict = SnapshotPayloadBuilder.mindCheckEntryPayload(entry)
        XCTAssertEqual(dict["isAccomplished"] as? String, "true")
    }

    func test_mindCheckEntryPayload_nonTodo_omitsIsAccomplished() {
        let entry = MindCheckEntry(
            category: .gratitude,
            text: "Grateful for family",
            timestamp: Date(),
            context: .morning
        )
        let dict = SnapshotPayloadBuilder.mindCheckEntryPayload(entry)
        XCTAssertNil(dict["isAccomplished"])
    }

    // MARK: - highlightData todos payload

    func test_build_highlightDataTodos_isIncludedInPayload() {
        let today = Calendar.current.startOfDay(for: Date())
        let todo = MindCheckEntry(category: .todo, text: "Buy groceries", timestamp: today, context: .morning)
        let highlight = HighlightData(todos: [todo])
        let snap = DailySmileySnapshotBuilder().withDate(today).withHighlightData(highlight).build()
        let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: today)
        XCTAssertNotNil(payload[0]["todos"])
    }

    func test_build_morningMindCheck_isAlsoRetainedInPayload() {
        let today = Calendar.current.startOfDay(for: Date())
        let mindCheckEntry = MindCheckEntry(category: .todo, text: "Meditate", timestamp: today, context: .morning)
        let todo = MindCheckEntry(category: .todo, text: "Buy groceries", timestamp: today, context: .morning)
        let highlight = HighlightData(todos: [todo])
        let snap = DailySmileySnapshotBuilder()
            .withDate(today)
            .withMorningMindCheck([mindCheckEntry])
            .withHighlightData(highlight)
            .build()
        let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: today)
        XCTAssertNotNil(payload[0]["morningMindCheck"])
        XCTAssertNotNil(payload[0]["todos"])
    }

    func test_build_accomplishedTodo_serialisesAsString_true() {
        let today = Calendar.current.startOfDay(for: Date())
        let todo = MindCheckEntry(
            category: .todo, text: "Run 5km", timestamp: today, context: .morning, isAccomplished: true
        )
        let highlight = HighlightData(todos: [todo])
        let snap = DailySmileySnapshotBuilder().withDate(today).withHighlightData(highlight).build()
        let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: today)
        let todos = payload[0]["todos"] as? [[String: Any]]
        XCTAssertEqual(todos?.first?["isAccomplished"] as? String, "true")
    }

    func test_build_unaccomplishedTodo_serialisesAsString_false() {
        let today = Calendar.current.startOfDay(for: Date())
        let todo = MindCheckEntry(
            category: .todo, text: "Run 5km", timestamp: today, context: .morning, isAccomplished: false
        )
        let highlight = HighlightData(todos: [todo])
        let snap = DailySmileySnapshotBuilder().withDate(today).withHighlightData(highlight).build()
        let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: today)
        let todos = payload[0]["todos"] as? [[String: Any]]
        XCTAssertEqual(todos?.first?["isAccomplished"] as? String, "false")
    }

    func test_build_unreviewedTodo_serialisesAsString_unreviewed() {
        let today = Calendar.current.startOfDay(for: Date())
        let todo = MindCheckEntry(category: .todo, text: "Run 5km", timestamp: today, context: .morning)
        let highlight = HighlightData(todos: [todo])
        let snap = DailySmileySnapshotBuilder().withDate(today).withHighlightData(highlight).build()
        let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: today)
        let todos = payload[0]["todos"] as? [[String: Any]]
        XCTAssertEqual(todos?.first?["isAccomplished"] as? String, "unreviewed")
    }

    func test_build_morningMindCheck_unreviewedEntry_serialisesAsString_unreviewed() {
        let today = Calendar.current.startOfDay(for: Date())
        let entry = MindCheckEntry(category: .todo, text: "Meditate", timestamp: today, context: .morning)
        let snap = DailySmileySnapshotBuilder().withDate(today).withMorningMindCheck([entry]).build()
        let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: today)
        let mindCheck = payload[0]["morningMindCheck"] as? [[String: Any]]
        XCTAssertEqual(mindCheck?.first?["isAccomplished"] as? String, "unreviewed")
    }

    // MARK: - userContext personalization payload

    func test_build_withUserContext_payloadContainsUserContextKey() {
        let today = Calendar.current.startOfDay(for: Date())
        let snap = DailySmileySnapshotBuilder().withDate(today).build()
        let context = BriefingUserContext(
            userName: "Alex",
            activityLevel: .moderatelyActive,
            dietaryGoal: .generalWellness
        )
        let payload = SnapshotPayloadBuilder.build(
            from: [snap],
            userContext: context,
            healthKitSleepData: [:],
            relativeTo: today
        )
        XCTAssertNotNil(payload["userContext"])
        XCTAssertNotNil(payload["userData"])
    }

    func test_build_withNilUserContext_payloadOmitsUserContextKey() {
        let today = Calendar.current.startOfDay(for: Date())
        let snap = DailySmileySnapshotBuilder().withDate(today).build()
        let payload = SnapshotPayloadBuilder.build(
            from: [snap],
            userContext: nil,
            healthKitSleepData: [:],
            relativeTo: today
        )
        XCTAssertNil(payload["userContext"])
        XCTAssertNotNil(payload["userData"])
    }

    // MARK: - Security: no sensitive content in payload keys

    func test_buildPayload_mealItems_areIncluded_forServerAnalysis() {
        let today = Calendar.current.startOfDay(for: Date())
        let meal = MealBuilder().withItems(["Salad", "Chicken"]).withScore(0.85).build()
        let snap = DailySmileySnapshotBuilder().withDate(today).withMeals([meal]).build()
        let payload = SnapshotPayloadBuilder.build(from: [snap], healthKitSleepData: [:], relativeTo: today)
        let meals = payload[0]["meals"] as? [[String: Any]]
        XCTAssertNotNil(meals)
        // Items are sent encrypted in transit (HTTPS); never logged
        XCTAssertNotNil(meals?.first?["items"])
    }

    func test_build_withHistoricalSummary_payloadContainsHistoricalContextKey() {
        let summary = HistoricalSummary(
            thirtyDayStats: PeriodStats(averageFoodScore: 0.72, daysLogged: 20),
            ninetyDayStats: nil,
            currentStreak: 5,
            bestDimension: .physicalLoad,
            worstDimension: .emotionalTone
        )
        let payload = SnapshotPayloadBuilder.build(
            from: [],
            userContext: nil,
            nudgeHistory: [],
            historicalSummary: summary,
            healthKitSleepData: [:],
            relativeTo: Date()
        )
        XCTAssertNotNil(payload["historicalContext"])
    }

    func test_build_historicalSummary_containsNoRawMealDescriptions() {
        let summary = HistoricalSummary(
            thirtyDayStats: PeriodStats(averageFoodScore: 0.65, daysLogged: 14),
            ninetyDayStats: nil,
            currentStreak: 3,
            bestDimension: nil,
            worstDimension: nil
        )
        let payload = SnapshotPayloadBuilder.build(
            from: [],
            userContext: nil,
            nudgeHistory: [],
            historicalSummary: summary,
            healthKitSleepData: [:],
            relativeTo: Date()
        )
        let context = payload["historicalContext"] as? [String: Any]
        XCTAssertNil(context?["meals"])
        XCTAssertNil(context?["items"])
    }
}
