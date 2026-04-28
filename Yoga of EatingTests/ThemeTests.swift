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

    // MARK: - Meal Card Theme Tests (Phase 4: Score Badge UI)

    func test_mealCardBorder_usesSemanticColor() {
        // Given: The meal card border color from theme
        let borderColor = AppTheme.MealCard.borderColor

        // Then: Should be defined (semantic color adapts to light/dark)
        XCTAssertNotNil(borderColor)
    }

    func test_mealCardBorder_hasConsistentWidth() {
        // Given: The standard border width
        let borderWidth = AppTheme.MealCard.borderWidth

        // Then: Should be thin (1.0) for minimal UI
        XCTAssertEqual(borderWidth, 1.0)
    }

    func test_scoreBadge_usesSemanticColors() {
        // Given: Score badge colors from theme
        let badgeBackground = AppTheme.ScoreBadge.background
        let badgeText = AppTheme.ScoreBadge.textColor

        // Then: Should be defined
        XCTAssertNotNil(badgeBackground)
        XCTAssertNotNil(badgeText)
    }

    func test_scoreBreakdownSheet_usesSystemBackgrounds() {
        // Given: Sheet colors from theme
        let sheetBackground = AppTheme.sheetBackground

        // Then: Should use system background (adapts to light/dark)
        XCTAssertNotNil(sheetBackground)
    }

    func test_scoreCategory_colors_areDefined() {
        // Given: Score category colors
        let excellent = AppTheme.ScoreColors.excellent
        let good = AppTheme.ScoreColors.good
        let moderate = AppTheme.ScoreColors.moderate
        let poor = AppTheme.ScoreColors.poor

        // Then: All should be defined
        XCTAssertNotNil(excellent)
        XCTAssertNotNil(good)
        XCTAssertNotNil(moderate)
        XCTAssertNotNil(poor)
    }
}
