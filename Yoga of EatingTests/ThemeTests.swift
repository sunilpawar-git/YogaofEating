import SwiftUI
import XCTest
@testable import Yoga_of_Eating

/// Tests for the app theme system.
/// Phase 8: Hybrid UI theme with warmer accents and cleaner backgrounds.
final class ThemeTests: XCTestCase {
    // MARK: - Background Color Tests

    func test_theme_backgroundColors_exist() {
        // Given
        let background = AppTheme.background
        let cardBackground = AppTheme.cardBackground
        let sheetBackground = AppTheme.sheetBackground

        // Then - colors should be defined
        XCTAssertNotNil(background)
        XCTAssertNotNil(cardBackground)
        XCTAssertNotNil(sheetBackground)
    }

    // MARK: - Accent Color Tests

    func test_theme_accentColors_exist() {
        // Given
        let warmAccent = AppTheme.warmAccent
        let successAccent = AppTheme.successAccent
        let warningAccent = AppTheme.warningAccent

        // Then
        XCTAssertNotNil(warmAccent)
        XCTAssertNotNil(successAccent)
        XCTAssertNotNil(warningAccent)
    }

    // MARK: - Spacing Tests

    func test_theme_spacing_values() {
        // Given
        let small = AppTheme.Spacing.small
        let medium = AppTheme.Spacing.medium
        let large = AppTheme.Spacing.large

        // Then - spacing should follow 8pt grid
        XCTAssertEqual(small, 8)
        XCTAssertEqual(medium, 16)
        XCTAssertEqual(large, 24)
    }

    // MARK: - Corner Radius Tests

    func test_theme_cornerRadius_values() {
        // Given
        let small = AppTheme.CornerRadius.small
        let medium = AppTheme.CornerRadius.medium
        let large = AppTheme.CornerRadius.large

        // Then
        XCTAssertGreaterThan(small, 0)
        XCTAssertGreaterThan(medium, small)
        XCTAssertGreaterThan(large, medium)
    }

    // MARK: - Typography Tests

    func test_theme_typography_exists() {
        // Given
        let headline = AppTheme.Typography.headline
        let body = AppTheme.Typography.body
        let caption = AppTheme.Typography.caption

        // Then
        XCTAssertNotNil(headline)
        XCTAssertNotNil(body)
        XCTAssertNotNil(caption)
    }
}
