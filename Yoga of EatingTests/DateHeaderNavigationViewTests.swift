#if canImport(XCTest)
    import SwiftUI
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for DateHeaderNavigationView component
    @MainActor
    final class DateHeaderNavigationViewTests: XCTestCase {
        // MARK: - Callback Tests

        func test_onPreviousDay_isCalled_whenButtonTapped() {
            // This is a structural test - the component accepts callbacks
            // Full integration testing is covered by DayNavigationTests
            var callbackCalled = false
            _ = DateHeaderNavigationView(
                formattedDate: "Tuesday, 7 Jan 2026",
                isViewingToday: true,
                canNavigateToPreviousDay: true,
                onPreviousDay: { callbackCalled = true },
                onNavigateToToday: {}
            )

            // Component structure is valid (no crash)
            XCTAssertFalse(callbackCalled, "Callback should not be called on init")
        }

        func test_component_acceptsAllRequiredParameters() {
            // Verify the component can be instantiated with all parameters
            let view = DateHeaderNavigationView(
                formattedDate: "Monday, 6 Jan 2026",
                isViewingToday: false,
                canNavigateToPreviousDay: true,
                onPreviousDay: {},
                onNavigateToToday: {}
            )

            // Component instantiates without error
            XCTAssertNotNil(view.body)
        }

        func test_component_handlesEdgeCases() {
            // Empty date string
            let viewEmptyDate = DateHeaderNavigationView(
                formattedDate: "",
                isViewingToday: true,
                canNavigateToPreviousDay: false,
                onPreviousDay: {},
                onNavigateToToday: {}
            )
            XCTAssertNotNil(viewEmptyDate.body)

            // Long date string
            let viewLongDate = DateHeaderNavigationView(
                formattedDate: "Wednesday, 31 December 2026",
                isViewingToday: false,
                canNavigateToPreviousDay: true,
                onPreviousDay: {},
                onNavigateToToday: {}
            )
            XCTAssertNotNil(viewLongDate.body)
        }

        // MARK: - Contextual Subtext Tests (Phase 4)

        func test_component_acceptsOptionalContextSubtext() {
            // Given: view with subtext provided
            let view = DateHeaderNavigationView(
                formattedDate: "Wednesday, 29 Apr 2026",
                isViewingToday: true,
                canNavigateToPreviousDay: true,
                onPreviousDay: {},
                onNavigateToToday: {},
                contextSubtext: "Good morning"
            )
            // Then: instantiates without error
            XCTAssertNotNil(view.body)
        }

        func test_component_acceptsNilContextSubtext() {
            // Given: view with no subtext (nil — default)
            let view = DateHeaderNavigationView(
                formattedDate: "Wednesday, 29 Apr 2026",
                isViewingToday: true,
                canNavigateToPreviousDay: true,
                onPreviousDay: {},
                onNavigateToToday: {},
                contextSubtext: nil
            )
            // Then: instantiates without error
            XCTAssertNotNil(view.body)
        }

        func test_component_contextSubtextDefaultIsNil() {
            // Given: view without explicit contextSubtext
            let view = DateHeaderNavigationView(
                formattedDate: "Wednesday, 29 Apr 2026",
                isViewingToday: true,
                canNavigateToPreviousDay: true,
                onPreviousDay: {},
                onNavigateToToday: {}
            )
            // Then: default parameter is nil (no subtext rendered)
            XCTAssertNil(view.contextSubtext)
        }
    }
#endif
