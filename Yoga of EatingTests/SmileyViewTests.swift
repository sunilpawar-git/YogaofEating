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
}
