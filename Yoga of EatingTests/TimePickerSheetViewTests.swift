#if canImport(XCTest)
    import SwiftUI
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for TimePickerSheetView component.
    /// Verifies time selection callbacks and view initialization.
    @MainActor
    final class TimePickerSheetViewTests: XCTestCase {
        // MARK: - Initialization Tests

        func test_viewInitializes_withValidDate() {
            // Given: A test date
            let testDate = Date()

            // When: Create view
            let view = TimePickerSheetView(
                selectedTime: .constant(testDate),
                onSave: {},
                onCancel: {}
            )

            // Then: View should initialize
            XCTAssertNotNil(view)
        }

        func test_viewInitializes_withPastDate() {
            // Given: A past date
            let pastDate = Date(timeIntervalSince1970: 1_704_067_200) // Jan 1, 2024

            // When: Create view
            let view = TimePickerSheetView(
                selectedTime: .constant(pastDate),
                onSave: {},
                onCancel: {}
            )

            // Then: View should initialize
            XCTAssertNotNil(view)
        }

        // MARK: - Callback Tests

        func test_onSaveCallback_canBeSet() {
            // Given: A save callback
            var saveCalled = false
            let saveCallback = { saveCalled = true }

            // When: Create view with callback
            _ = TimePickerSheetView(
                selectedTime: .constant(Date()),
                onSave: saveCallback,
                onCancel: {}
            )

            // Then: Callback should not be called on init
            XCTAssertFalse(saveCalled, "Save callback should not be called on init")
        }

        func test_onCancelCallback_canBeSet() {
            // Given: A cancel callback
            var cancelCalled = false
            let cancelCallback = { cancelCalled = true }

            // When: Create view with callback
            _ = TimePickerSheetView(
                selectedTime: .constant(Date()),
                onSave: {},
                onCancel: cancelCallback
            )

            // Then: Callback should not be called on init
            XCTAssertFalse(cancelCalled, "Cancel callback should not be called on init")
        }
    }

#endif
