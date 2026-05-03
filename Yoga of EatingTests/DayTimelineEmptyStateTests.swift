import XCTest
@testable import Yoga_of_Eating

/// Tests for the empty-state and smiley animation logic introduced in Phase 2.
/// Covers TimelineAnimationState (pure logic) and Strings.Timeline (SSOT).
final class DayTimelineEmptyStateTests: XCTestCase {
    // MARK: - TimelineAnimationState.shouldPulse

    func test_shouldPulse_todayWithNoMeals_returnsTrue() {
        // Given: today's view, no meals
        // When / Then
        XCTAssertTrue(TimelineAnimationState.shouldPulse(mealCount: 0, isToday: true))
    }

    func test_shouldPulse_todayWithOneMeal_returnsFalse() {
        // Given: today's view, first meal logged
        XCTAssertFalse(TimelineAnimationState.shouldPulse(mealCount: 1, isToday: true))
    }

    func test_shouldPulse_todayWithMultipleMeals_returnsFalse() {
        // Given: today's view, multiple meals logged
        XCTAssertFalse(TimelineAnimationState.shouldPulse(mealCount: 3, isToday: true))
    }

    func test_shouldPulse_historicalDayWithNoMeals_returnsFalse() {
        // Given: historical day (read-only), no meals — no pulse on past days
        XCTAssertFalse(TimelineAnimationState.shouldPulse(mealCount: 0, isToday: false))
    }

    func test_shouldPulse_historicalDayWithMeals_returnsFalse() {
        // Given: historical day with meals
        XCTAssertFalse(TimelineAnimationState.shouldPulse(mealCount: 2, isToday: false))
    }

    // MARK: - TimelineAnimationState.shouldShowEmptyStateGreeting

    func test_shouldShowEmptyStateGreeting_todayNoMeals_returnsTrue() {
        XCTAssertTrue(TimelineAnimationState.shouldShowEmptyStateGreeting(mealCount: 0, isToday: true))
    }

    func test_shouldShowEmptyStateGreeting_todayWithMeal_returnsFalse() {
        XCTAssertFalse(TimelineAnimationState.shouldShowEmptyStateGreeting(mealCount: 1, isToday: true))
    }

    func test_shouldShowEmptyStateGreeting_historicalDay_returnsFalse() {
        XCTAssertFalse(TimelineAnimationState.shouldShowEmptyStateGreeting(mealCount: 0, isToday: false))
    }

    // MARK: - TimelineAnimationState.shouldShowQuote

    func test_shouldShowQuote_todayWithMeals_returnsTrue() {
        // Quote appears after first meal as reward signal
        XCTAssertTrue(TimelineAnimationState.shouldShowQuote(mealCount: 1, isToday: true))
        XCTAssertTrue(TimelineAnimationState.shouldShowQuote(mealCount: 3, isToday: true))
    }

    func test_shouldShowQuote_todayNoMeals_returnsFalse() {
        // Quote hidden in empty state to avoid disconnected static element
        XCTAssertFalse(TimelineAnimationState.shouldShowQuote(mealCount: 0, isToday: true))
    }

    func test_shouldShowQuote_historicalDay_alwaysTrue() {
        // Historical days always show quote (it's a summary view, not interactive)
        XCTAssertTrue(TimelineAnimationState.shouldShowQuote(mealCount: 0, isToday: false))
        XCTAssertTrue(TimelineAnimationState.shouldShowQuote(mealCount: 3, isToday: false))
    }

    // MARK: - Strings.Timeline SSOT verification

    func test_strings_tapToLog_isNotEmpty() {
        XCTAssertFalse(Strings.Timeline.tapToLog.isEmpty)
    }

    func test_strings_tapToLogWithInsight_isNotEmpty() {
        XCTAssertFalse(Strings.Timeline.tapToLogWithInsight.isEmpty)
    }

    func test_strings_tapToLogWithInsight_containsTapToLog() {
        // The insight variant should include the base "TAP TO LOG" prefix
        XCTAssertTrue(Strings.Timeline.tapToLogWithInsight.contains(Strings.Timeline.tapToLog))
    }

    func test_strings_emptyStateGreeting_isNotEmpty() {
        XCTAssertFalse(Strings.Timeline.emptyStateGreeting.isEmpty)
    }

    func test_strings_emptyStateGreeting_matchesExpected() {
        XCTAssertEqual(Strings.Timeline.emptyStateGreeting, "Start your day's journal")
    }

    func test_strings_quoteAccessibility_isNotEmpty() {
        XCTAssertFalse(Strings.Timeline.quoteAccessibility.isEmpty)
    }

    // MARK: - AppTheme.Animation constants

    func test_animation_breathingScale_isAboveOne() {
        // Scale must be > 1.0 to produce a visible pulse
        XCTAssertGreaterThan(AppTheme.Animation.breathingScale, 1.0)
    }

    func test_animation_breathingScale_isWithinSafeRange() {
        // Must not be so large it disrupts layout
        XCTAssertLessThanOrEqual(AppTheme.Animation.breathingScale, 1.1)
    }

    func test_animation_breathingPulse_isDefined() {
        // Verify the animation constant is accessible (compile-time check via non-nil)
        let animation = AppTheme.Animation.breathingPulse
        XCTAssertNotNil(animation)
    }
}
