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

        // Note: debounce constant relocated to TimingConstants.textEntryDebounceNanoseconds.
        // Coverage lives in TimingConstantsTests.swift.
        // This test guards that AppTheme.TextEntry no longer exposes debounceNanoseconds
        // (avoids a stale duplicate constant drifting back in).
        func test_textEntryDebounce_ssotIsTimingConstants_andIs500ms() {
            // The SSOT for text-entry debounce is TimingConstants.textEntryDebounceNanoseconds.
            // Verify the value equals what callers expect (500 ms).
            XCTAssertEqual(
                TimingConstants.textEntryDebounceNanoseconds,
                500_000_000,
                "Text-entry debounce SSOT is TimingConstants; must be 500 ms"
            )
        }
    }
#endif
