import XCTest
@testable import Yoga_of_Eating

final class ScoringThresholdsTests: XCTestCase {
    func test_healthyThreshold_isGreaterThanUnhealthyThreshold() {
        XCTAssertGreaterThan(ScoringThresholds.healthy, ScoringThresholds.unhealthy)
    }

    func test_healthyThreshold_isWithinZeroToOne() {
        XCTAssertGreaterThan(ScoringThresholds.healthy, 0)
        XCTAssertLessThan(ScoringThresholds.healthy, 1)
    }

    func test_unhealthyThreshold_isWithinZeroToOne() {
        XCTAssertGreaterThan(ScoringThresholds.unhealthy, 0)
        XCTAssertLessThan(ScoringThresholds.unhealthy, 1)
    }

    func test_foodDebtBadDay_isBetweenUnhealthyAndHealthy() {
        XCTAssertGreaterThan(ScoringThresholds.foodDebtBadDay, ScoringThresholds.unhealthy)
        XCTAssertLessThan(ScoringThresholds.foodDebtBadDay, ScoringThresholds.healthy)
    }

    func test_neutral_isExactlyHalf() {
        XCTAssertEqual(ScoringThresholds.neutral, 0.5)
    }

    func test_high_isAboveHealthy() {
        XCTAssertGreaterThan(ScoringThresholds.high, ScoringThresholds.healthy)
    }

    func test_minimumConsistentDays_isPositive() {
        XCTAssertGreaterThan(ScoringThresholds.minimumConsistentDays, 0)
    }

    func test_allThresholds_areInStandaloneFile() {
        // Verifies the type exists independently and is accessible without MealLogicService coupling.
        // If ScoringThresholds moves to its own file this test still compiles — coupling test.
        _ = ScoringThresholds.healthy
        _ = ScoringThresholds.unhealthy
        _ = ScoringThresholds.foodDebtBadDay
        _ = ScoringThresholds.neutral
        _ = ScoringThresholds.high
        _ = ScoringThresholds.minimumConsistentDays
    }
}
