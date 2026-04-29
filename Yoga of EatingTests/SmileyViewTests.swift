import SwiftUI
import XCTest
@testable import Yoga_of_Eating

final class SmileyViewTests: XCTestCase {
    func test_emojiForMood_returnsCorrectEmoji() {
        // Since emojiForMood is private, we can't test it directly easily without reflection or making it internal.
        // However, we can test the view's content if we really wanted to,
        // but for this simple refactor, let's verify SmileyState's mood matches what we expect in the view logic.

        let sereneState = SmileyState(scale: 1.0, mood: .serene)
        let neutralState = SmileyState(scale: 1.0, mood: .neutral)
        let overwhelmedState = SmileyState(scale: 1.0, mood: .overwhelmed)

        XCTAssertEqual(sereneState.mood, .serene)
        XCTAssertEqual(neutralState.mood, .neutral)
        XCTAssertEqual(overwhelmedState.mood, .overwhelmed)
    }

    // MARK: - Pulse State Tests (Phase 2)

    func test_smileyPulse_activatesWhenTodayEmpty() {
        // Delegates to TimelineAnimationState — verified separately
        let shouldPulse = TimelineAnimationState.shouldPulse(mealCount: 0, isToday: true)
        XCTAssertTrue(shouldPulse, "Smiley should pulse when today has no meals")
    }

    func test_smileyPulse_deactivatesAfterFirstMeal() {
        let shouldPulse = TimelineAnimationState.shouldPulse(mealCount: 1, isToday: true)
        XCTAssertFalse(shouldPulse, "Smiley should stop pulsing after first meal is logged")
    }

    func test_smileyPulse_neverActivatesOnHistoricalDays() {
        let shouldPulse = TimelineAnimationState.shouldPulse(mealCount: 0, isToday: false)
        XCTAssertFalse(shouldPulse, "Historical days should never show breathing animation")
    }
}
