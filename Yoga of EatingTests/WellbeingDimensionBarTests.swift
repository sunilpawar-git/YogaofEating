import XCTest
@testable import Yoga_of_Eating

// Tests that WellbeingDimensionBar is a non-private shared component.
// These tests will fail to compile until the struct is extracted from
// WellbeingBreakdownSheet.swift as a non-private type.
final class WellbeingDimensionBarTests: XCTestCase {
    func test_wellbeingDimensionBar_canBeInstantiatedAsSharedComponent() {
        let bar = WellbeingDimensionBar(
            dimension: .physicalLoad,
            value: 0.5,
            isDominant: false,
            mealCount: 1
        )
        XCTAssertNotNil(bar)
    }

    func test_wellbeingDimensionBar_accessibilityLabel_allDimensions() {
        for dimension in WellbeingDimension.allCases {
            let label = String(
                format: Strings.WellbeingBreakdown.dimensionBarAccessibilityFmt,
                dimension.displayName,
                50
            )
            XCTAssertFalse(label.isEmpty, "Accessibility label must not be empty for \(dimension)")
            XCTAssertTrue(
                label.contains(dimension.displayName),
                "Accessibility label must contain dimension name for \(dimension)"
            )
        }
    }

    func test_wellbeingDimensionBar_subtitle_physicalLoad_singular() {
        let subtitle = WellbeingDimension.physicalLoad.subtitle(mealCount: 1)
        XCTAssertTrue(subtitle.contains("1"), "Singular subtitle must include the count '1'")
    }

    func test_wellbeingDimensionBar_subtitle_physicalLoad_plural() {
        let plural = WellbeingDimension.physicalLoad.subtitle(mealCount: 3)
        let singular = WellbeingDimension.physicalLoad.subtitle(mealCount: 1)
        XCTAssertTrue(plural.contains("3"), "Plural subtitle must include the count '3'")
        XCTAssertNotEqual(plural, singular, "Plural and singular subtitles must differ")
    }

    func test_wellbeingDimensionBar_value_clampedAbove1_doesNotCrash() {
        let bar = WellbeingDimensionBar(
            dimension: .emotionalTone,
            value: 1.5,
            isDominant: false,
            mealCount: 2
        )
        XCTAssertNotNil(bar)
    }

    func test_wellbeingDimensionBar_value_clampedBelow0_doesNotCrash() {
        let bar = WellbeingDimensionBar(
            dimension: .cognitiveClarity,
            value: -0.1,
            isDominant: true,
            mealCount: 0
        )
        XCTAssertNotNil(bar)
    }
}
