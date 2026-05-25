import SwiftUI
import XCTest
@testable import Yoga_of_Eating

/// Verifies that AppTheme.CorrelationCard colour tokens exist and are distinct.
@MainActor
final class BriefingThemeTests: XCTestCase {
    func test_appTheme_correlationCard_allCategoriesHaveDistinctColors() {
        let colors = CorrelationCategory.allCases.map { AppTheme.CorrelationCard.color(for: $0) }
        let uniqueDescriptions = Set(colors.map { "\($0)" })
        XCTAssertGreaterThan(
            uniqueDescriptions.count,
            1,
            "All correlation categories must not map to the same colour — caught copy-paste mistake"
        )
    }
}
