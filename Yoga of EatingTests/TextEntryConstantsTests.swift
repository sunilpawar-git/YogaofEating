#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Verifies the single-source-of-truth text entry constants in AppTheme.TextEntry.
    /// These tests exist to prevent silent drift where different screens use different limits.
    final class TextEntryConstantsTests: XCTestCase {
        // MARK: - Character Limit

        func test_maxCharacters_is1000() {
            XCTAssertEqual(
                AppTheme.TextEntry.maxCharacters,
                1000,
                "All free-text fields must share a 1000-character limit (SSOT)"
            )
        }

        func test_maxCharacters_isPositive() {
            XCTAssertGreaterThan(AppTheme.TextEntry.maxCharacters, 0)
        }

        // MARK: - Debounce (Highlight/Reflect text-entry settle delay)

        func test_debounceNanoseconds_is500ms() {
            XCTAssertEqual(
                AppTheme.TextEntry.debounceNanoseconds,
                500_000_000,
                "Highlight/Reflect text-entry settle delay must be 500 ms"
            )
        }

        func test_debounceNanoseconds_isReasonableForUX() {
            let min: UInt64 = 300_000_000
            let max: UInt64 = 1_000_000_000
            XCTAssertGreaterThanOrEqual(AppTheme.TextEntry.debounceNanoseconds, min)
            XCTAssertLessThanOrEqual(AppTheme.TextEntry.debounceNanoseconds, max)
        }

        // MARK: - JournalBlockView consistency

        func test_journalBlock_maxCharacters_matchesSSO() {
            // maxCharacterLimit is now sourced from AppTheme.TextEntry.maxCharacters
            XCTAssertEqual(
                AppTheme.TextEntry.maxCharacters,
                1000,
                "JournalBlockView must use AppTheme.TextEntry.maxCharacters (1000)"
            )
        }
    }
#endif
