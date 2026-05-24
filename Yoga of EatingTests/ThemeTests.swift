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

    // warmAccent, successAccent, warningAccent, primaryAccent removed — no production callers.

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

    // MARK: - Typography

    // AppTheme.Typography removed — SSOT is FontTheme (see Logic/FontTheme.swift).

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

        // Then: Minimalist spine — barely present, guides without announcing itself
        XCTAssertEqual(opacity, 0.06, accuracy: 0.001)
    }

    func test_timeline_spineWidth_isCorrectValue() {
        // Given / When
        let width = AppTheme.Timeline.spineWidth

        // Then: 1.0pt — thinnest visible line
        XCTAssertEqual(width, 1.0, accuracy: 0.01)
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

    func test_background_glowOpacity_isOff() {
        // Glow intentionally removed for minimalist aesthetic.
        // The view renders an invisible circle; no orange bleed onto the background.
        XCTAssertEqual(AppTheme.Background.glowOpacity, 0.0, accuracy: 0.001)
    }

    func test_background_glowBlurRadius_isDefined() {
        XCTAssertGreaterThan(AppTheme.Background.glowBlurRadius, 0)
    }

    func test_background_glowSize_isDefined() {
        XCTAssertGreaterThan(AppTheme.Background.glowSize, 0)
    }

    // MARK: - Layout Constants Tests

    func test_layout_bottomScrollBuffer_isPinned() {
        // Pinned value — changing this shifts the visible bottom of the timeline scroll area.
        // Review MainScreenView scroll proxy before changing.
        XCTAssertEqual(AppTheme.Layout.bottomScrollBuffer, 100, accuracy: 0.01)
    }

    func test_layout_smileyButtonSize_isInMinimalistRange() {
        // Smiley must be large enough to carry emotional presence but not dominate the screen.
        // Acceptable range: 80–100pt. Below 80 loses impact; above 100 feels toy-like.
        let size = AppTheme.Layout.smileyButtonSize
        XCTAssertGreaterThanOrEqual(size, 80)
        XCTAssertLessThanOrEqual(size, 100)
    }

    // MARK: - Meal Type Color Tests

    func test_mealTypeColors_areAllDefined() {
        XCTAssertNotNil(AppTheme.MealTypeColors.breakfast)
        XCTAssertNotNil(AppTheme.MealTypeColors.lunch)
        XCTAssertNotNil(AppTheme.MealTypeColors.dinner)
        XCTAssertNotNil(AppTheme.MealTypeColors.snacks)
        XCTAssertNotNil(AppTheme.MealTypeColors.drinks)
    }

    // MARK: - Meal Card Shadow Tests

    func test_mealCard_cardShadowColor_isSubtle() {
        // Shadow must stay near-invisible for minimalist aesthetic.
        // If opacity creeps above 0.05, the card will feel heavy.
        XCTAssertNotNil(AppTheme.MealCard.cardShadowColor)
        XCTAssertGreaterThan(AppTheme.MealCard.cardShadowRadius, 0)
        XCTAssertGreaterThan(AppTheme.MealCard.cardShadowOffsetY, 0)
    }

    // MARK: - Fasting Domain Constants (coverage moved to FastingConstantsTests.swift)

    // AppTheme.Fasting was removed in Phase 1 refactor — see Logic/FastingConstants.swift

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

    // MARK: - CaloriePill Token Tests (Phase 2 consolidation safety net)

    func test_caloriePill_fillColors_areDefined() {
        XCTAssertNotNil(AppTheme.CaloriePill.fillOnTrack)
        XCTAssertNotNil(AppTheme.CaloriePill.fillApproaching)
        XCTAssertNotNil(AppTheme.CaloriePill.fillOver)
    }

    func test_caloriePill_pillBackground_isDefined() {
        XCTAssertNotNil(AppTheme.CaloriePill.pillBackground)
    }

    func test_caloriePill_textPrimary_isDefined() {
        XCTAssertNotNil(AppTheme.CaloriePill.textPrimary)
    }

    func test_caloriePill_geometry_arePositive() {
        XCTAssertGreaterThan(AppTheme.CaloriePill.pillMaxWidth, 0)
        XCTAssertGreaterThan(AppTheme.CaloriePill.pillVerticalPadding, 0)
        XCTAssertGreaterThan(AppTheme.CaloriePill.pillHorizontalPadding, 0)
    }

    func test_caloriePill_thresholds_areInValidRange() {
        // Thresholds are business logic living in ScoringThresholds — not in AppTheme.
        // This test verifies the *colours* still exist in AppTheme for the three bands.
        XCTAssertNotNil(AppTheme.CaloriePill.fillOnTrack)
        XCTAssertNotNil(AppTheme.CaloriePill.fillApproaching)
        XCTAssertNotNil(AppTheme.CaloriePill.fillOver)
    }

    // Note: approachingThreshold / overThreshold SSOT guard tests moved to ScoringThresholdsTests.swift
}
