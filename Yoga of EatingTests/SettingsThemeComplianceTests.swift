import SwiftUI
import XCTest
@testable import Yoga_of_Eating

/// SSOT coverage for FontTheme and AppTheme tokens introduced in Phase 11.
///
/// A compile error means the token is missing — the Red phase in TDD.
/// These tests verify token existence and their exact backing values.
@MainActor
final class SettingsThemeComplianceTests: XCTestCase {
    // MARK: - FontTheme tokens

    func test_fontTheme_displayName_exists() {
        // If this compiles, the token exists.
        let font: Font = FontTheme.displayName
        XCTAssertNotNil(font)
    }

    func test_fontTheme_displaySubtitle_exists() {
        let font: Font = FontTheme.displaySubtitle
        XCTAssertNotNil(font)
    }

    // MARK: - AppTheme.CloudSync new tokens

    func test_cloudSync_syncButtonColor_exists() {
        let color: Color = AppTheme.CloudSync.syncButtonColor
        XCTAssertNotNil(color)
    }

    func test_cloudSync_successColor_exists() {
        let color: Color = AppTheme.CloudSync.successColor
        XCTAssertNotNil(color)
    }

    func test_cloudSync_errorColor_exists() {
        let color: Color = AppTheme.CloudSync.errorColor
        XCTAssertNotNil(color)
    }

    func test_cloudSync_progressViewScale_exists() {
        let scale: CGFloat = AppTheme.CloudSync.progressViewScale
        XCTAssertGreaterThan(scale, 0)
        XCTAssertLessThanOrEqual(scale, 1)
    }

    func test_cloudSync_progressViewScale_isPoint8() {
        XCTAssertEqual(AppTheme.CloudSync.progressViewScale, 0.8, accuracy: 0.001)
    }

    // MARK: - Strings.Common.cancel used in SettingsView alerts

    func test_stringsCommon_cancel_exists() {
        XCTAssertEqual(Strings.Common.cancel, "Cancel")
    }
}
