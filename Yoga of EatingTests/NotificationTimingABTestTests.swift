// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for NotificationTimingABTest wake-time parsing and A/B variant distribution.
    /// Phase A3 (bounds validation) and C2 (deterministic distribution) — TDD Red-Green-Refactor.
    @MainActor
    final class NotificationTimingABTestTests: XCTestCase {
        // MARK: - Setup

        override func setUp() {
            super.setUp()
            // Clean up any stored wake time to isolate tests
            UserDefaults.standard.removeObject(forKey: "user_wake_time_test_user")
        }

        override func tearDown() {
            UserDefaults.standard.removeObject(forKey: "user_wake_time_test_user")
            super.tearDown()
        }

        // MARK: - A3: Wake Time Bounds Validation

        func test_predictWakeTime_validTime_returnsParsedValue() {
            // Arrange: Store a valid time
            WakeTimePredictor.updateWakeTime((hour: 8, minute: 30), for: "test_user")

            // Act
            let result = WakeTimePredictor.predictWakeTime(for: "test_user")

            // Assert
            XCTAssertEqual(result.hour, 8)
            XCTAssertEqual(result.minute, 30)
        }

        func test_predictWakeTime_invalidHour_returnsDefault() {
            // Arrange: Manually store an out-of-range hour (25 is invalid)
            UserDefaults.standard.set("25:30", forKey: "user_wake_time_test_user")

            // Act
            let result = WakeTimePredictor.predictWakeTime(for: "test_user")

            // Assert: should fall back to default (7, 0)
            XCTAssertEqual(result.hour, 7)
            XCTAssertEqual(result.minute, 0)
        }

        func test_predictWakeTime_invalidMinute_returnsDefault() {
            // Arrange: Manually store an out-of-range minute (90 is invalid)
            UserDefaults.standard.set("7:90", forKey: "user_wake_time_test_user")

            // Act
            let result = WakeTimePredictor.predictWakeTime(for: "test_user")

            // Assert: should fall back to default (7, 0)
            XCTAssertEqual(result.hour, 7)
            XCTAssertEqual(result.minute, 0)
        }

        func test_predictWakeTime_malformedString_returnsDefault() {
            // Arrange: Store a non-parseable string
            UserDefaults.standard.set("not:a:valid:time:string", forKey: "user_wake_time_test_user")

            // Act
            let result = WakeTimePredictor.predictWakeTime(for: "test_user")

            // Assert: should fall back to default (7, 0)
            XCTAssertEqual(result.hour, 7)
            XCTAssertEqual(result.minute, 0)
        }

        func test_predictWakeTime_noStoredValue_returnsDefault() {
            // Arrange: Nothing stored for this user

            // Act
            let result = WakeTimePredictor.predictWakeTime(for: "test_user")

            // Assert
            XCTAssertEqual(result.hour, 7)
            XCTAssertEqual(result.minute, 0)
        }

        func test_predictWakeTime_boundaryHour23_returnsValue() {
            // Arrange: 23 is the valid upper bound for hours
            WakeTimePredictor.updateWakeTime((hour: 23, minute: 59), for: "test_user")

            // Act
            let result = WakeTimePredictor.predictWakeTime(for: "test_user")

            // Assert
            XCTAssertEqual(result.hour, 23)
            XCTAssertEqual(result.minute, 59)
        }
    }
#endif
