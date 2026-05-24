#if canImport(XCTest)
    import UserNotifications
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class NotificationManagerTests: XCTestCase {
        var sut: NotificationManager!
        var mockCenter: MockNotificationCenter!

        override func setUp() {
            super.setUp()
            self.mockCenter = MockNotificationCenter()
            self.sut = NotificationManager(center: self.mockCenter)

            // Enable notification settings for tests
            UserDefaults.standard.set(true, forKey: "morning_nudge_enabled")
            UserDefaults.standard.set(true, forKey: "meal_reminders_enabled")
        }

        override func tearDown() {
            self.sut = nil
            self.mockCenter = nil

            // Clean up UserDefaults
            UserDefaults.standard.removeObject(forKey: "morning_nudge_enabled")
            UserDefaults.standard.removeObject(forKey: "meal_reminders_enabled")

            super.tearDown()
        }

        func test_scheduleMorningNudge_createsRequest() {
            self.sut.scheduleMorningNudge()

            XCTAssertEqual(self.mockCenter.requests.count, 1)
            let request = self.mockCenter.requests.first
            XCTAssertEqual(request?.content.title, "Good Morning!")
            XCTAssertTrue(request?.trigger is UNCalendarNotificationTrigger)
        }

        func test_scheduleMealReminder_createsRequest() {
            self.sut.scheduleMealReminder(label: "Lunch", hour: 11, minute: 0)

            XCTAssertEqual(self.mockCenter.requests.count, 1)
            let request = self.mockCenter.requests.first
            XCTAssertEqual(request?.content.title, "Meal Time")
            XCTAssertTrue(request?.content.body.contains("lunch") ?? false)
        }

        // MARK: - TDD Tests for Default-ON Behavior

        func test_scheduleMorningNudge_defaultsToEnabled_whenKeyMissing() {
            // Given: Key is NOT set in UserDefaults (simulating fresh install)
            UserDefaults.standard.removeObject(forKey: "morning_nudge_enabled")

            // When
            self.sut.scheduleMorningNudge()

            // Then: Should still schedule (default ON)
            XCTAssertEqual(self.mockCenter.requests.count, 1, "Morning nudge should be scheduled when key is missing")
        }

        func test_scheduleMealReminder_defaultsToEnabled_whenKeyMissing() {
            // Given: Key is NOT set in UserDefaults (simulating fresh install)
            UserDefaults.standard.removeObject(forKey: "meal_reminders_enabled")

            // When
            self.sut.scheduleMealReminder(label: "Breakfast", hour: 8, minute: 0)

            // Then: Should still schedule (default ON)
            XCTAssertEqual(self.mockCenter.requests.count, 1, "Meal reminder should be scheduled when key is missing")
        }

        func test_scheduleMorningNudge_doesNotSchedule_whenExplicitlyDisabled() {
            // Given: Key is explicitly set to false
            UserDefaults.standard.set(false, forKey: "morning_nudge_enabled")

            // When
            self.sut.scheduleMorningNudge()

            // Then: Should NOT schedule
            XCTAssertEqual(
                self.mockCenter.requests.count,
                0,
                "Morning nudge should NOT be scheduled when explicitly disabled"
            )
        }

        func test_scheduleMealReminder_doesNotSchedule_whenExplicitlyDisabled() {
            // Given: Key is explicitly set to false
            UserDefaults.standard.set(false, forKey: "meal_reminders_enabled")

            // When
            self.sut.scheduleMealReminder(label: "Dinner", hour: 19, minute: 0)

            // Then: Should NOT schedule
            XCTAssertEqual(
                self.mockCenter.requests.count,
                0,
                "Meal reminder should NOT be scheduled when explicitly disabled"
            )
        }

        // MARK: - TDD: scheduleMorningNudge(at:)

        func test_scheduleMorningNudge_withCustomTime_usesCorrectHour() {
            // Given
            let time = Self.makeTime(hour: 9, minute: 15)

            // When
            self.sut.scheduleMorningNudge(at: time)

            // Then
            let trigger = self.mockCenter.requests.first?.trigger as? UNCalendarNotificationTrigger
            XCTAssertEqual(trigger?.dateComponents.hour, 9)
        }

        func test_scheduleMorningNudge_withCustomTime_usesCorrectMinute() {
            // Given
            let time = Self.makeTime(hour: 9, minute: 15)

            // When
            self.sut.scheduleMorningNudge(at: time)

            // Then
            let trigger = self.mockCenter.requests.first?.trigger as? UNCalendarNotificationTrigger
            XCTAssertEqual(trigger?.dateComponents.minute, 15)
        }

        func test_scheduleMorningNudge_withCustomTime_setsRepeating() {
            // When
            self.sut.scheduleMorningNudge(at: Self.makeTime(hour: 7, minute: 30))

            // Then
            let trigger = self.mockCenter.requests.first?.trigger as? UNCalendarNotificationTrigger
            XCTAssertEqual(trigger?.repeats, true)
        }

        func test_scheduleMorningNudge_withCustomTime_usesMorningNudgeIdentifier() {
            // When
            self.sut.scheduleMorningNudge(at: Self.makeTime(hour: 7, minute: 30))

            // Then
            XCTAssertEqual(self.mockCenter.requests.first?.identifier, "morning_nudge")
        }

        // MARK: - TDD: cancelMorningNudge uses injected center

        func test_cancelMorningNudge_callsRemoveOnInjectedCenter() {
            // When
            self.sut.cancelMorningNudge()

            // Then: must go through self.center, not UNUserNotificationCenter.current()
            XCTAssertTrue(
                self.mockCenter.removedIdentifiers.contains("morning_nudge"),
                "cancelMorningNudge must route through the injected center"
            )
        }

        func test_cancelMealReminders_callsRemoveOnInjectedCenter() {
            // When
            self.sut.cancelMealReminders()

            // Then
            XCTAssertTrue(
                self.mockCenter.removedIdentifiers.contains("meal_reminder_Breakfast"),
                "cancelMealReminders must route through the injected center"
            )
            XCTAssertTrue(self.mockCenter.removedIdentifiers.contains("meal_reminder_Lunch"))
            XCTAssertTrue(self.mockCenter.removedIdentifiers.contains("meal_reminder_Dinner"))
        }

        // MARK: - Helpers

        private static func makeTime(hour: Int, minute: Int) -> Date {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            return Calendar.current.date(from: components) ?? Date()
        }
    }

    // Mock for UNUserNotificationCenter
    @MainActor
    final class MockNotificationCenter: NotificationCenterProtocol {
        var requests: [UNNotificationRequest] = []
        /// Identifiers passed to removePendingNotificationRequests(withIdentifiers:).
        /// Used to verify cancellation routes through the injected center.
        var removedIdentifiers: [String] = []

        func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
            self.requests.append(request)
            completionHandler?(nil)
        }

        func requestAuthorization(
            options _: UNAuthorizationOptions,
            completionHandler: @escaping (Bool, Error?) -> Void
        ) {
            completionHandler(true, nil)
        }

        func removeAllPendingNotificationRequests() {
            self.requests.removeAll()
        }

        func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
            self.removedIdentifiers.append(contentsOf: identifiers)
            self.requests.removeAll { identifiers.contains($0.identifier) }
        }
    }

#endif
