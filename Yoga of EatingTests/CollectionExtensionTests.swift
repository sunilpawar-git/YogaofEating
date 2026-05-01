#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for the Collection+Average extension (Phase C1 — DRY).
    @MainActor
    final class CollectionExtensionTests: XCTestCase {
        func test_average_emptyCollection_returnsNil() {
            let empty: [Double] = []
            XCTAssertNil(empty.average())
        }

        func test_average_singleElement_returnsElement() {
            let single = [0.75]
            let result = single.average()
            XCTAssertNotNil(result)
            XCTAssertEqual(result!, 0.75, accuracy: 0.0001)
        }

        func test_average_multipleElements_returnsCorrectMean() {
            let values: [Double] = [0.4, 0.6, 0.8]
            let result = values.average()
            XCTAssertNotNil(result)
            XCTAssertEqual(result!, 0.6, accuracy: 0.0001)
        }
    }
#endif
