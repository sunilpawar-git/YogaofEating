#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class BulletTextFieldTests: XCTestCase {
        // MARK: - DeleteDetectingTextField

        func test_deleteBackward_whenEmpty_callsOnDeleteWhenEmpty() {
            var called = false
            let tf = DeleteDetectingTextField()
            tf.onDeleteWhenEmpty = { called = true }
            tf.text = ""

            tf.deleteBackward()

            XCTAssertTrue(called)
        }

        func test_deleteBackward_whenNonEmpty_doesNotCallOnDeleteWhenEmpty() {
            var called = false
            let tf = DeleteDetectingTextField()
            tf.onDeleteWhenEmpty = { called = true }
            tf.text = "chicken"

            tf.deleteBackward()

            XCTAssertFalse(called)
        }

        func test_deleteBackward_withNilCallback_doesNotCrash() {
            let tf = DeleteDetectingTextField()
            tf.onDeleteWhenEmpty = nil
            tf.text = ""

            XCTAssertNoThrow(tf.deleteBackward())
        }

        func test_deleteBackward_afterClearingText_callsOnDeleteWhenEmpty() {
            var deleteCount = 0
            let tf = DeleteDetectingTextField()
            tf.onDeleteWhenEmpty = { deleteCount += 1 }

            tf.text = "a"
            tf.deleteBackward() // clears "a" — not empty before this call
            XCTAssertEqual(deleteCount, 0, "Should not fire when field had content")

            tf.text = "" // simulate UIKit having updated the text
            tf.deleteBackward() // now empty
            XCTAssertEqual(deleteCount, 1, "Should fire on second backspace when field is empty")
        }
    }
#endif
