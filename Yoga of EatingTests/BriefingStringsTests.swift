import SwiftUI
import XCTest
@testable import Yoga_of_Eating

/// Verifies that all Strings.Briefing entries are defined and non-empty.
/// These are compile-time SSOT guards — if a key is missing, the module won't build.
@MainActor
final class BriefingStringsTests: XCTestCase {
    // MARK: - Phase 2 TDD: FontTheme tokens for sprint views

    func test_fontTheme_moodEmoji_tokenExists() {
        let _: Font = FontTheme.moodEmoji
        XCTAssert(true, "FontTheme.moodEmoji SSOT token must exist")
    }

    func test_fontTheme_preparingIcon_tokenExists() {
        let _: Font = FontTheme.preparingIcon
        XCTAssert(true, "FontTheme.preparingIcon SSOT token must exist")
    }

    // MARK: - Phase 2 TDD: AppTheme token for InsightPreparingSheet button

    func test_appTheme_briefing_refreshButtonBackground_exists() {
        let _: Color = AppTheme.Briefing.refreshButtonBackground
        XCTAssert(true, "AppTheme.Briefing.refreshButtonBackground SSOT token must exist")
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

    func test_strings_briefing_patternsSection_isNonEmpty() {
        XCTAssertFalse(Strings.Briefing.patternsSection.isEmpty)
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
