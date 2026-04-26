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

        // MARK: - A.1 Regression: smart nudges must not wipe morning nudge

        func test_scheduleSmartNudges_doesNotRemoveMorningNudge() {
            // Given: morning nudge is already scheduled
            self.sut.scheduleMorningNudge()
            XCTAssertEqual(
                self.mockCenter.requests.count, 1,
                "Pre-condition: morning nudge should be scheduled"
            )

            // When: smart nudges are scheduled
            let times = [DateComponents(hour: 9, minute: 0)]
            self.sut.scheduleSmartNudges(
                times: times, message: "test"
            )

            // Then: morning nudge must still be present
            let morningNudge = self.mockCenter.requests.first {
                $0.identifier == "morning_nudge"
            }
            XCTAssertNotNil(
                morningNudge,
                "Morning nudge must survive scheduleSmartNudges"
            )
            XCTAssertEqual(
                self.mockCenter.requests.count, 2,
                "Should have morning nudge + 1 smart nudge"
            )
        }

        func test_scheduleSmartNudges_usesIdentifierRemoval_notRemoveAll() {
            self.sut.scheduleMorningNudge()
            self.sut.scheduleSmartNudges(
                times: [DateComponents(hour: 9, minute: 0)], message: "m"
            )

            // removeAll should NOT have been triggered
            XCTAssertFalse(
                self.mockCenter.requests.isEmpty,
                "removeAll must not have been called (morning nudge should remain)"
            )
            let wasRemoveAllCalled = !self.mockCenter.removedIdentifiers.isEmpty
            XCTAssertTrue(
                wasRemoveAllCalled,
                "Should have called removePendingNotificationRequests(withIdentifiers:)"
            )
        }

        // MARK: - A.4 Regression: cancelMorningNudge only cancels morning nudge

        func test_cancelMorningNudge_doesNotCancelSmartNudges() {
            // Given: morning nudge + smart nudge scheduled
            self.sut.scheduleMorningNudge()
            self.sut.scheduleSmartNudges(
                times: [DateComponents(hour: 9, minute: 0)], message: "m"
            )
            XCTAssertEqual(self.mockCenter.requests.count, 2)

            // When: cancel only morning nudge
            self.sut.cancelMorningNudge()

            // Then: smart nudge must still exist
            let smartNudge = self.mockCenter.requests.first {
                $0.identifier.hasPrefix("smart_nudge_")
            }
            XCTAssertNotNil(
                smartNudge,
                "Smart nudge must survive cancelMorningNudge"
            )
            XCTAssertEqual(
                self.mockCenter.requests.count, 1,
                "Only morning nudge should be removed"
            )
        }

        // MARK: - A.6: StorageKeys used for morning nudge key

        func test_morningNudge_usesStorageKeys() {
            UserDefaults.standard.set(
                false, forKey: StorageKeys.morningNudgeEnabled
            )
            self.sut.scheduleMorningNudge()
            XCTAssertEqual(
                self.mockCenter.requests.count, 0,
                "Should respect StorageKeys.morningNudgeEnabled"
            )
            UserDefaults.standard.removeObject(
                forKey: StorageKeys.morningNudgeEnabled
            )
        }
    }

    // Mock for UNUserNotificationCenter
    @MainActor
    final class MockNotificationCenter: NotificationCenterProtocol {
        var requests: [UNNotificationRequest] = []
        var removedIdentifiers: [String] = []

        func add(
            _ request: UNNotificationRequest,
            withCompletionHandler completionHandler: ((Error?) -> Void)?
        ) {
            self.requests.append(request)
            completionHandler?(nil)
        }

        nonisolated func requestAuthorization(
            options _: UNAuthorizationOptions,
            completionHandler: @escaping (Bool, Error?) -> Void
        ) {
            completionHandler(true, nil)
        }

        func removeAllPendingNotificationRequests() {
            self.requests.removeAll()
        }

        func removePendingNotificationRequests(
            withIdentifiers identifiers: [String]
        ) {
            self.removedIdentifiers.append(contentsOf: identifiers)
            self.requests.removeAll {
                identifiers.contains($0.identifier)
            }
        }
    }

#endif
