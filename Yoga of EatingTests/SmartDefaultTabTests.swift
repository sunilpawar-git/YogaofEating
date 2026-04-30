import XCTest
@testable import Yoga_of_Eating

final class SmartDefaultTabTests: XCTestCase {
    func test_beforeNoon_noSleep_returnsHighlight() {
        let tab = RootTabView.defaultTab(currentHour: 8, hasSleepLogged: false)
        XCTAssertEqual(tab, 0, "Before noon + no sleep → Highlight (0)")
    }

    func test_beforeNoon_withSleep_returnsEnergise() {
        let tab = RootTabView.defaultTab(currentHour: 8, hasSleepLogged: true)
        XCTAssertEqual(tab, 1, "Before noon + sleep logged → Energise (1)")
    }

    func test_atNoon_noSleep_returnsEnergise() {
        let tab = RootTabView.defaultTab(currentHour: 12, hasSleepLogged: false)
        XCTAssertEqual(tab, 1, "At noon (12) → Energise (1)")
    }

    func test_afterNoon_noSleep_returnsEnergise() {
        let tab = RootTabView.defaultTab(currentHour: 15, hasSleepLogged: false)
        XCTAssertEqual(tab, 1, "After noon + no sleep → Energise (1)")
    }

    func test_afterNoon_withSleep_returnsEnergise() {
        let tab = RootTabView.defaultTab(currentHour: 20, hasSleepLogged: true)
        XCTAssertEqual(tab, 1, "After noon + sleep logged → Energise (1)")
    }

    func test_midnight_noSleep_returnsHighlight() {
        let tab = RootTabView.defaultTab(currentHour: 0, hasSleepLogged: false)
        XCTAssertEqual(tab, 0, "Midnight + no sleep → Highlight (0)")
    }

    func test_elevenAM_noSleep_returnsHighlight() {
        let tab = RootTabView.defaultTab(currentHour: 11, hasSleepLogged: false)
        XCTAssertEqual(tab, 0, "11 AM + no sleep → Highlight (0)")
    }
}
