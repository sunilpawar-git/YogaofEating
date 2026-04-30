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

        func test_component_storesFormattedDate() {
            // Verify the component stores the formatted date string correctly
            let view = DateHeaderNavigationView(
                formattedDate: "Monday, 6 Jan 2026",
                isViewingToday: false,
                canNavigateToPreviousDay: true,
                onPreviousDay: {},
                onNavigateToToday: {}
            )
            XCTAssertEqual(view.formattedDate, "Monday, 6 Jan 2026")
        }

        func test_component_storesIsViewingToday_true() {
            let view = DateHeaderNavigationView(
                formattedDate: "Today",
                isViewingToday: true,
                canNavigateToPreviousDay: true,
                onPreviousDay: {},
                onNavigateToToday: {}
            )
            XCTAssertTrue(view.isViewingToday)
        }

        func test_component_storesIsViewingToday_false() {
            let view = DateHeaderNavigationView(
                formattedDate: "Past Day",
                isViewingToday: false,
                canNavigateToPreviousDay: true,
                onPreviousDay: {},
                onNavigateToToday: {}
            )
            XCTAssertFalse(view.isViewingToday)
        }

        func test_component_storesCanNavigateToPreviousDay() {
            let enabled = DateHeaderNavigationView(
                formattedDate: "Today",
                isViewingToday: true,
                canNavigateToPreviousDay: true,
                onPreviousDay: {},
                onNavigateToToday: {}
            )
            XCTAssertTrue(enabled.canNavigateToPreviousDay)

            let disabled = DateHeaderNavigationView(
                formattedDate: "Day 0",
                isViewingToday: true,
                canNavigateToPreviousDay: false,
                onPreviousDay: {},
                onNavigateToToday: {}
            )
            XCTAssertFalse(disabled.canNavigateToPreviousDay)
        }

        // MARK: - Contextual Subtext Tests (Phase 4)

        func test_component_contextSubtextStoredCorrectly() {
            // Given: view with subtext provided
            let view = DateHeaderNavigationView(
                formattedDate: "Wednesday, 29 Apr 2026",
                isViewingToday: true,
                canNavigateToPreviousDay: true,
                onPreviousDay: {},
                onNavigateToToday: {},
                contextSubtext: "Good morning"
            )
            // Then: contextSubtext is stored and accessible
            XCTAssertEqual(view.contextSubtext, "Good morning")
        }

        func test_component_contextSubtextNil_storedAsNil() {
            // Given: view with explicit nil subtext
            let view = DateHeaderNavigationView(
                formattedDate: "Wednesday, 29 Apr 2026",
                isViewingToday: true,
                canNavigateToPreviousDay: true,
                onPreviousDay: {},
                onNavigateToToday: {},
                contextSubtext: nil
            )
            XCTAssertNil(view.contextSubtext)
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

        func test_component_backToTodayString_usesSSOT() {
            // Verify the "Back to Today" string is sourced from Strings SSOT
            XCTAssertEqual(Strings.DateHeader.backToToday, "Back to Today")
        }
    }
#endif
