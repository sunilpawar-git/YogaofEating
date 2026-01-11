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
    }

    // Mock for UNUserNotificationCenter
    @MainActor
    final class MockNotificationCenter: NotificationCenterProtocol {
        var requests: [UNNotificationRequest] = []

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
    }

#endif
