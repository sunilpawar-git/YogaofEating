import XCTest
@testable import Yoga_of_Eating

/// Verifies that all Strings.Briefing entries are defined and non-empty.
/// These are compile-time SSOT guards — if a key is missing, the module won't build.
@MainActor
final class BriefingStringsTests: XCTestCase {
    func test_strings_briefing_cardTitle_isNotEmpty() {
        XCTAssertFalse(Strings.Briefing.cardTitle.isEmpty)
    }

    func test_strings_briefing_greetingMorning_isNotEmpty() {
        XCTAssertFalse(Strings.Briefing.greetingMorning.isEmpty)
    }

    func test_strings_briefing_greetingAfternoon_isNotEmpty() {
        XCTAssertFalse(Strings.Briefing.greetingAfternoon.isEmpty)
    }

    func test_strings_briefing_greetingEvening_isNotEmpty() {
        XCTAssertFalse(Strings.Briefing.greetingEvening.isEmpty)
    }

    func test_strings_briefing_greetingNight_isNotEmpty() {
        XCTAssertFalse(Strings.Briefing.greetingNight.isEmpty)
    }

    func test_strings_briefing_todaysSnapshotSection_isNonEmpty() {
        XCTAssertFalse(Strings.Briefing.todaysSnapshotSection.isEmpty)
    }

    func test_strings_briefing_insightsTitleFormat_containsPlaceholder() {
        XCTAssertTrue(
            Strings.Briefing.insightsTitleFormat.contains("%@"),
            "insightsTitleFormat must contain a %@ placeholder for the day name"
        )
    }

    func test_strings_briefing_insightsTitleFormat_producesExpectedOutput() {
        let result = String(format: Strings.Briefing.insightsTitleFormat, "Monday")
        XCTAssertTrue(result.contains("Monday"))
        XCTAssertTrue(result.contains("Insights"))
    }
}
