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

    // MARK: - Timeline Constants Tests (Phase 1)

    func test_timeline_spineOpacity_isCorrectValue() {
        // Given / When
        let opacity = AppTheme.Timeline.spineOpacity

        // Then: Spine must be visible (0.18) — not the old invisible 0.10
        XCTAssertEqual(opacity, 0.18, accuracy: 0.001)
    }

    func test_timeline_spineWidth_isCorrectValue() {
        // Given / When
        let width = AppTheme.Timeline.spineWidth

        // Then: 1.5pt — crisp without being heavy
        XCTAssertEqual(width, 1.5, accuracy: 0.01)
    }

    func test_timeline_spineWidth_isPositive() {
        XCTAssertGreaterThan(AppTheme.Timeline.spineWidth, 0)
    }

    func test_timeline_spineOpacity_isInValidRange() {
        let opacity = AppTheme.Timeline.spineOpacity
        XCTAssertGreaterThan(opacity, 0.0, "Spine must be visible")
        XCTAssertLessThan(opacity, 1.0, "Spine must not be fully opaque")
    }

    func test_timeline_fastingSignificantColor_isDefined() {
        XCTAssertNotNil(AppTheme.Timeline.fastingSignificantColor)
    }

    func test_timeline_fastingDefaultColor_isDefined() {
        XCTAssertNotNil(AppTheme.Timeline.fastingDefaultColor)
    }

    // MARK: - Background Glow Constants Tests (Phase 5)

    func test_background_glowOpacity_isDefined() {
        let opacity = AppTheme.Background.glowOpacity
        XCTAssertGreaterThan(opacity, 0.0)
        XCTAssertLessThan(opacity, 1.0)
    }

    func test_background_glowBlurRadius_isDefined() {
        XCTAssertGreaterThan(AppTheme.Background.glowBlurRadius, 0)
    }

    func test_background_glowSize_isDefined() {
        XCTAssertGreaterThan(AppTheme.Background.glowSize, 0)
    }

    // MARK: - Layout Constants Tests (Phase 2)

    func test_layout_headerTopPadding_isPositive() {
        XCTAssertGreaterThan(AppTheme.Layout.headerTopPadding, 0)
    }

    func test_layout_headerBottomPadding_isPositive() {
        XCTAssertGreaterThan(AppTheme.Layout.headerBottomPadding, 0)
    }

    func test_layout_bottomScrollBuffer_isPositive() {
        XCTAssertGreaterThan(AppTheme.Layout.bottomScrollBuffer, 0)
    }

    func test_layout_dragThreshold_isPositive() {
        XCTAssertGreaterThan(AppTheme.Layout.dragThreshold, 0)
    }

    func test_layout_inputSheetHeight_isPositive() {
        XCTAssertGreaterThan(AppTheme.Layout.inputSheetHeight, 0)
    }

    func test_layout_feelingSheetHeight_isPositive() {
        XCTAssertGreaterThan(AppTheme.Layout.feelingSheetHeight, 0)
    }

    // MARK: - Fasting Domain Constants Tests (Phase 2)

    func test_fasting_significanceHoursThreshold_isTwelve() {
        XCTAssertEqual(AppTheme.Fasting.significanceHoursThreshold, 12.0, accuracy: 0.001)
    }

    func test_fasting_secondsPerHour_isCorrect() {
        XCTAssertEqual(AppTheme.Fasting.secondsPerHour, 3600, accuracy: 0.001)
    }

    func test_fasting_secondsPerMinute_isCorrect() {
        XCTAssertEqual(AppTheme.Fasting.secondsPerMinute, 60, accuracy: 0.001)
    }

    // MARK: - DateContext Constants Tests (Phase 2)

    func test_dateContext_morningHourThreshold_isTen() {
        XCTAssertEqual(AppTheme.DateContext.morningHourThreshold, 10)
    }

    // MARK: - Animation Standard Duration Tests (Phase 2)

    func test_animation_standardDuration_isPositive() {
        XCTAssertGreaterThan(AppTheme.Animation.standardDuration, 0)
    }

    func test_animation_standardDuration_isReasonable() {
        // Should be between 0.1s and 1.0s for a UI transition
        XCTAssertGreaterThan(AppTheme.Animation.standardDuration, 0.1)
        XCTAssertLessThan(AppTheme.Animation.standardDuration, 1.0)
    }
}
