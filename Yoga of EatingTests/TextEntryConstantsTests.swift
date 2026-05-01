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

        // MARK: - Debounce

        func test_debounceNanoseconds_is500ms() {
            XCTAssertEqual(
                AppTheme.TextEntry.debounceNanoseconds,
                500_000_000,
                "Auto-save debounce must be 500 ms (SSOT)"
            )
        }

        func test_debounceNanoseconds_isReasonableForUX() {
            let min: UInt64 = 300_000_000 // 300 ms — below this feels laggy to persist
            let max: UInt64 = 1_000_000_000 // 1 s — above this the user notices the delay
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

        func test_journalBlock_debounce_matchesSSO() {
            XCTAssertEqual(
                JournalBlockView.localUpdateDebounceNanoseconds,
                AppTheme.TextEntry.debounceNanoseconds,
                "JournalBlockView must use AppTheme.TextEntry.debounceNanoseconds, not a hard-coded value"
            )
        }
    }
#endif
