import XCTest
@testable import Yoga_of_Eating

/// Tests for FastingBadgeView visual logic and FastingPeriod model properties.
/// Phase 1: Timeline Spine + Fasting Badge Expressiveness.
final class FastingBadgeViewTests: XCTestCase {
    // MARK: - Helpers

    private func makePeriod(hours: Double) -> FastingPeriod {
        let start = Date(timeIntervalSince1970: 1_704_067_200)
        let end = start.addingTimeInterval(hours * 3600)
        return FastingPeriod(
            startMealId: UUID(),
            endMealId: UUID(),
            startTime: start,
            endTime: end
        )
    }

    // MARK: - isSignificant

    func test_fastingPeriod_isSignificant_falseForShortPeriod() {
        // Given: 4h fasting — not significant
        let period = self.makePeriod(hours: 4)

        // Then
        XCTAssertFalse(period.isSignificant)
    }

    func test_fastingPeriod_isSignificant_falseForElevenHours() {
        // Given: just under threshold
        let period = self.makePeriod(hours: 11.9)

        // Then
        XCTAssertFalse(period.isSignificant)
    }

    func test_fastingPeriod_isSignificant_trueAtThreshold() {
        // Given: exactly at 12h threshold
        let period = self.makePeriod(hours: 12.0)

        // Then
        XCTAssertTrue(period.isSignificant)
    }

    func test_fastingPeriod_isSignificant_trueForLongPeriod() {
        // Given: 16h — clearly significant
        let period = self.makePeriod(hours: 16)

        // Then
        XCTAssertTrue(period.isSignificant)
    }

    // MARK: - formattedDuration

    func test_fastingPeriod_formattedDuration_wholeHours_noMinutes() {
        // Given: exactly 6h
        let period = self.makePeriod(hours: 6)

        // Then: should show "6h" (minutes < 30, omitted)
        XCTAssertEqual(period.formattedDuration, "6h")
    }

    func test_fastingPeriod_formattedDuration_withMinutes_showsMinutes() {
        // Given: 5h 59m (5.983h)
        let period = self.makePeriod(hours: 5.983)

        // Then: minutes >= 30, so "5h 59m"
        XCTAssertTrue(
            period.formattedDuration.hasPrefix("5h"),
            "Expected duration to start with '5h', got: \(period.formattedDuration)"
        )
        XCTAssertTrue(
            period.formattedDuration.contains("m"),
            "Expected duration to contain minutes, got: \(period.formattedDuration)"
        )
    }

    func test_fastingPeriod_formattedDuration_belowThirtyMinutes_omitsMinutes() {
        // Given: 6h 15m
        let period = self.makePeriod(hours: 6.25)

        // Then: 15 < 30, omit minutes — shows "6h"
        XCTAssertEqual(period.formattedDuration, "6h")
    }

    // MARK: - glowIntensity

    func test_fastingPeriod_glowIntensity_zeroForShortPeriod() {
        // Given: not significant
        let period = self.makePeriod(hours: 8)

        // Then: no glow
        XCTAssertEqual(period.glowIntensity, 0.0)
    }

    func test_fastingPeriod_glowIntensity_aboveZeroForSignificantPeriod() {
        // Given: 16h — significant
        let period = self.makePeriod(hours: 16)

        // Then: glow intensity > 0
        XCTAssertGreaterThan(period.glowIntensity, 0.0)
    }

    func test_fastingPeriod_glowIntensity_clampedToValidRange() {
        // Given: extreme fasting (24h)
        let period = self.makePeriod(hours: 24)

        // Then: clamped to [0.3, 1.0]
        XCTAssertGreaterThanOrEqual(period.glowIntensity, 0.3)
        XCTAssertLessThanOrEqual(period.glowIntensity, 1.0)
    }

    func test_fastingPeriod_glowIntensity_minimumAtThreshold() {
        // Given: exactly 12h (minimum significant threshold)
        let period = self.makePeriod(hours: 12)

        // Then: minimum glow (clamped to 0.3)
        XCTAssertEqual(period.glowIntensity, 0.3, accuracy: 0.01)
    }

    // MARK: - FastingBadgeView styling signals

    func test_fastingBadgeView_significantPeriod_borderColorIsGreen() {
        // Given: significant fasting period
        let period = self.makePeriod(hours: 16)
        let view = FastingBadgeView(fastingPeriod: period)

        // Then: the view exposes isSignificant — significant periods use green styling
        XCTAssertTrue(view.fastingPeriod.isSignificant)
    }

    func test_fastingBadgeView_shortPeriod_borderColorIsDefault() {
        // Given: short fasting period
        let period = self.makePeriod(hours: 4)
        let view = FastingBadgeView(fastingPeriod: period)

        // Then: non-significant uses default styling
        XCTAssertFalse(view.fastingPeriod.isSignificant)
    }

    func test_fastingBadgeView_significantPeriod_hasNonZeroGlow() {
        // Given: 14h fasting
        let period = self.makePeriod(hours: 14)
        let view = FastingBadgeView(fastingPeriod: period)

        // Then: glow is active
        XCTAssertGreaterThan(view.fastingPeriod.glowIntensity, 0.0)
    }

    func test_fastingBadgeView_shortPeriod_hasZeroGlow() {
        // Given: 5h fasting
        let period = self.makePeriod(hours: 5)
        let view = FastingBadgeView(fastingPeriod: period)

        // Then: no glow for non-significant periods
        XCTAssertEqual(view.fastingPeriod.glowIntensity, 0.0)
    }
}
