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

    // MARK: - CaloriePill Fraction Thresholds (SSOT guard — Phase 2 consolidation)

    func test_caloriePillApproachingFraction_isExactlySeventyPercent() {
        // SSOT guard: review CaloriePillData.fillColor if this changes
        XCTAssertEqual(ScoringThresholds.caloriePillApproachingFraction, 0.70, accuracy: 0.001)
    }

    func test_caloriePillOverFraction_isExactlyNinetyFivePercent() {
        // SSOT guard: review CaloriePillData.fillColor if this changes
        XCTAssertEqual(ScoringThresholds.caloriePillOverFraction, 0.95, accuracy: 0.001)
    }

    func test_caloriePillThresholds_approachingIsLessThanOver() {
        XCTAssertLessThan(
            ScoringThresholds.caloriePillApproachingFraction,
            ScoringThresholds.caloriePillOverFraction,
            "approachingFraction must be below overFraction"
        )
    }

    func test_caloriePillThresholds_areInValidRange() {
        XCTAssertGreaterThan(ScoringThresholds.caloriePillApproachingFraction, 0.0)
        XCTAssertLessThan(ScoringThresholds.caloriePillApproachingFraction, 1.0)
        XCTAssertGreaterThan(ScoringThresholds.caloriePillOverFraction, 0.0)
        XCTAssertLessThanOrEqual(ScoringThresholds.caloriePillOverFraction, 1.0)
    }
}
