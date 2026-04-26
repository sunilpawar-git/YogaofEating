import XCTest
@testable import Yoga_of_Eating

final class SmartNudgeServiceTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func makeSnapshot(
        daysAgo: Int,
        meals: [Meal],
        from today: Date = Date()
    ) -> DailySmileySnapshot {
        let date = self.calendar.date(
            byAdding: .day, value: -daysAgo, to: today
        )!
        return DailySmileySnapshot(
            id: UUID(),
            date: date,
            smileyState: SmileyState(scale: 0.5, mood: .neutral),
            meals: meals,
            mealCount: meals.count,
            averageHealthScore: 0.7
        )
    }

    private func makeMeal(
        type: MealType, hour: Int
    ) -> Meal {
        var components = self.calendar.dateComponents(
            [.year, .month, .day], from: Date()
        )
        components.hour = hour
        components.minute = 0
        let timestamp = self.calendar.date(from: components) ?? Date()
        return Meal(
            timestamp: timestamp,
            mealType: type,
            items: ["test"],
            healthScore: 0.7
        )
    }

    // MARK: - suggestedMealTimes

    func testSuggestedMealTimesReturnsDefaultsForEmptySnapshots() {
        let result = SmartNudgeService.suggestedMealTimes(from: [])

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].hour, 8)
        XCTAssertEqual(result[1].hour, 13)
        XCTAssertEqual(result[2].hour, 20)
    }

    func testSuggestedMealTimesUsesAverageFromHistory() {
        let today = Date()
        var snapshots: [DailySmileySnapshot] = []

        for day in 1...7 {
            let meals = [
                makeMeal(type: .breakfast, hour: 9),
                makeMeal(type: .lunch, hour: 14),
                makeMeal(type: .dinner, hour: 21)
            ]
            snapshots.append(
                self.makeSnapshot(daysAgo: day, meals: meals, from: today)
            )
        }

        let result = SmartNudgeService.suggestedMealTimes(from: snapshots)

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].hour, 9)
        XCTAssertEqual(result[1].hour, 14)
        XCTAssertEqual(result[2].hour, 21)
    }

    // MARK: - nudgeMessage

    func testNudgeMessageWithActiveStreak() {
        let streak = ConsistencyStreak(
            current: 5, best: 5, todayLogged: true
        )

        let message = SmartNudgeService.nudgeMessage(streak: streak)

        XCTAssertTrue(message.contains("5"))
    }

    func testNudgeMessageWithNoStreak() {
        let streak = ConsistencyStreak(
            current: 0, best: 3, todayLogged: false
        )

        let message = SmartNudgeService.nudgeMessage(streak: streak)

        XCTAssertFalse(message.contains("streak"))
    }

    // MARK: - NotificationManager Smart Nudges

    @MainActor
    func testScheduleSmartNudgesCallsCenter() {
        let mockCenter = SmartNudgeMockCenter()
        let manager = NotificationManager(center: mockCenter)

        UserDefaults.standard.set(
            true, forKey: StorageKeys.mealRemindersEnabled
        )

        let times = [
            DateComponents(hour: 9, minute: 0),
            DateComponents(hour: 14, minute: 0)
        ]

        manager.scheduleSmartNudges(
            times: times, message: Strings.Nudge.gentle
        )

        XCTAssertFalse(mockCenter.removedIdentifiers.isEmpty)
        XCTAssertEqual(mockCenter.addedRequests.count, 2)

        let firstTrigger = mockCenter.addedRequests[0].trigger
            as? UNCalendarNotificationTrigger
        XCTAssertEqual(firstTrigger?.dateComponents.hour, 9)

        UserDefaults.standard.removeObject(
            forKey: StorageKeys.mealRemindersEnabled
        )
    }

    // MARK: - NotificationManager gating integration

    @MainActor
    func testScheduleSmartNudgesRespectsDisabledSetting() {
        let mockCenter = SmartNudgeMockCenter()
        let manager = NotificationManager(center: mockCenter)

        UserDefaults.standard.set(
            false, forKey: StorageKeys.mealRemindersEnabled
        )

        manager.scheduleSmartNudges(
            times: [DateComponents(hour: 9, minute: 0)],
            message: Strings.Nudge.gentle
        )

        XCTAssertEqual(
            mockCenter.addedRequests.count, 0,
            "Should not schedule when meal reminders disabled"
        )
        XCTAssertTrue(
            mockCenter.removedIdentifiers.isEmpty,
            "Should not even attempt removal when disabled"
        )

        UserDefaults.standard.removeObject(
            forKey: StorageKeys.mealRemindersEnabled
        )
    }

    // MARK: - Integration: streak observed after loadData

    @MainActor
    func testViewModelCurrentStreakAfterLoadData() {
        let viewModel = MainViewModel(
            logicService: MockMealLogicService(),
            persistenceService: MockPersistenceService(),
            historicalService: MockHistoricalDataService()
        )

        viewModel.loadData()

        // With no meals and no historical data, streak must be 0
        XCTAssertEqual(viewModel.currentStreak.current, 0)
        XCTAssertFalse(viewModel.currentStreak.todayLogged)
    }
}

@MainActor
private final class SmartNudgeMockCenter: NotificationCenterProtocol {
    var removedIdentifiers: [String] = []
    var addedRequests: [UNNotificationRequest] = []

    nonisolated func requestAuthorization(
        options _: UNAuthorizationOptions,
        completionHandler: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        completionHandler(true, nil)
    }

    func add(
        _ request: UNNotificationRequest,
        withCompletionHandler handler: (@Sendable (Error?) -> Void)?
    ) {
        self.addedRequests.append(request)
        handler?(nil)
    }

    func removeAllPendingNotificationRequests() {
        self.addedRequests.removeAll()
    }

    func removePendingNotificationRequests(
        withIdentifiers identifiers: [String]
    ) {
        self.removedIdentifiers.append(contentsOf: identifiers)
        self.addedRequests.removeAll {
            identifiers.contains($0.identifier)
        }
    }
}
