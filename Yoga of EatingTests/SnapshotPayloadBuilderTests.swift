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
        XCTAssertEqual(dict["isAccomplished"] as? Bool, true)
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
}
