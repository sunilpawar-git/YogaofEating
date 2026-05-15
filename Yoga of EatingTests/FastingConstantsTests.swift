import XCTest
@testable import Yoga_of_Eating

/// Tests for FastingConstants — single source of truth for fasting domain constants.
/// These constants are pure physics/time values used by the Foundation-layer model;
/// they must never live in a SwiftUI theme file.
final class FastingConstantsTests: XCTestCase {
    // MARK: - secondsPerHour

    func test_secondsPerHour_isExactly3600() {
        XCTAssertEqual(FastingConstants.secondsPerHour, 3600, accuracy: 0.001)
    }

    func test_secondsPerHour_isPositive() {
        XCTAssertGreaterThan(FastingConstants.secondsPerHour, 0)
    }

    // MARK: - secondsPerMinute

    func test_secondsPerMinute_isExactly60() {
        XCTAssertEqual(FastingConstants.secondsPerMinute, 60, accuracy: 0.001)
    }

    func test_secondsPerMinute_isPositive() {
        XCTAssertGreaterThan(FastingConstants.secondsPerMinute, 0)
    }

    func test_secondsPerHour_equalsSixtySecondsPerMinute() {
        // Physical invariant: 1 hour == 60 minutes
        XCTAssertEqual(
            FastingConstants.secondsPerHour,
            60 * FastingConstants.secondsPerMinute,
            accuracy: 0.001,
            "secondsPerHour must equal 60 × secondsPerMinute"
        )
    }

    // MARK: - significanceHoursThreshold

    func test_significanceHoursThreshold_isExactlyTwelve() {
        // SSOT guard — review FastingPeriod.isSignificant and glowIntensity if this changes
        XCTAssertEqual(FastingConstants.significanceHoursThreshold, 12.0, accuracy: 0.001)
    }

    func test_significanceHoursThreshold_isPositive() {
        XCTAssertGreaterThan(FastingConstants.significanceHoursThreshold, 0)
    }

    func test_significanceHoursThreshold_isReasonable() {
        // Clinically, intermittent fasting starts at 12–16h; 12 is the minimum meaningful gate
        XCTAssertGreaterThanOrEqual(FastingConstants.significanceHoursThreshold, 8.0)
        XCTAssertLessThanOrEqual(FastingConstants.significanceHoursThreshold, 24.0)
    }
}
