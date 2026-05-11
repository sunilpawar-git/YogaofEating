#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class WellbeingDimensionsTests: XCTestCase {
        // MARK: - Overall computation

        func test_overall_isAverageOfFourDimensions() {
            let sut = WellbeingDimensions(
                physicalLoad: 0.8,
                emotionalTone: 0.6,
                cognitiveClarity: 0.4,
                behavioralMomentum: 0.2
            )
            XCTAssertEqual(sut.overall, 0.5, accuracy: 0.001)
        }

        func test_overall_allZero_isZero() {
            let sut = WellbeingDimensions(
                physicalLoad: 0.0,
                emotionalTone: 0.0,
                cognitiveClarity: 0.0,
                behavioralMomentum: 0.0
            )
            XCTAssertEqual(sut.overall, 0.0, accuracy: 0.001)
        }

        func test_overall_allOne_isOne() {
            let sut = WellbeingDimensions(
                physicalLoad: 1.0,
                emotionalTone: 1.0,
                cognitiveClarity: 1.0,
                behavioralMomentum: 1.0
            )
            XCTAssertEqual(sut.overall, 1.0, accuracy: 0.001)
        }

        // MARK: - Clamping

        func test_dimensions_clampAboveOne_onInit() {
            let sut = WellbeingDimensions(
                physicalLoad: 1.5,
                emotionalTone: 2.0,
                cognitiveClarity: 99.0,
                behavioralMomentum: 1.001
            )
            XCTAssertEqual(sut.physicalLoad, 1.0)
            XCTAssertEqual(sut.emotionalTone, 1.0)
            XCTAssertEqual(sut.cognitiveClarity, 1.0)
            XCTAssertEqual(sut.behavioralMomentum, 1.0)
        }

        func test_dimensions_clampBelowZero_onInit() {
            let sut = WellbeingDimensions(
                physicalLoad: -0.1,
                emotionalTone: -1.0,
                cognitiveClarity: -99.0,
                behavioralMomentum: -0.001
            )
            XCTAssertEqual(sut.physicalLoad, 0.0)
            XCTAssertEqual(sut.emotionalTone, 0.0)
            XCTAssertEqual(sut.cognitiveClarity, 0.0)
            XCTAssertEqual(sut.behavioralMomentum, 0.0)
        }

        // MARK: - Neutral preset

        func test_neutral_hasAllPointFive() {
            let sut = WellbeingDimensions.neutral
            XCTAssertEqual(sut.physicalLoad, 0.5)
            XCTAssertEqual(sut.emotionalTone, 0.5)
            XCTAssertEqual(sut.cognitiveClarity, 0.5)
            XCTAssertEqual(sut.behavioralMomentum, 0.5)
        }

        func test_neutral_overall_isPointFive() {
            XCTAssertEqual(WellbeingDimensions.neutral.overall, 0.5, accuracy: 0.001)
        }

        // MARK: - Equatable

        func test_equatable_sameValues_areEqual() {
            let a = WellbeingDimensions(
                physicalLoad: 0.5,
                emotionalTone: 0.6,
                cognitiveClarity: 0.7,
                behavioralMomentum: 0.8
            )
            let b = WellbeingDimensions(
                physicalLoad: 0.5,
                emotionalTone: 0.6,
                cognitiveClarity: 0.7,
                behavioralMomentum: 0.8
            )
            XCTAssertEqual(a, b)
        }

        func test_equatable_differentValues_areNotEqual() {
            let a = WellbeingDimensions(
                physicalLoad: 0.5,
                emotionalTone: 0.5,
                cognitiveClarity: 0.5,
                behavioralMomentum: 0.5
            )
            let b = WellbeingDimensions(
                physicalLoad: 0.6,
                emotionalTone: 0.5,
                cognitiveClarity: 0.5,
                behavioralMomentum: 0.5
            )
            XCTAssertNotEqual(a, b)
        }

        // MARK: - Codable

        func test_codableRoundTrip_preservesAllDimensions() throws {
            let sut = WellbeingDimensions(
                physicalLoad: 0.7,
                emotionalTone: 0.6,
                cognitiveClarity: 0.8,
                behavioralMomentum: 0.55
            )
            let data = try JSONEncoder().encode(sut)
            let decoded = try JSONDecoder().decode(WellbeingDimensions.self, from: data)
            XCTAssertEqual(sut, decoded)
        }

        // MARK: - WellbeingDimension enum

        func test_wellbeingDimension_allCases_haveDisplayName() {
            for dimension in WellbeingDimension.allCases {
                XCTAssertFalse(dimension.displayName.isEmpty, "Missing displayName for \(dimension)")
            }
        }

        func test_wellbeingDimension_codableRoundTrip() throws {
            for dimension in WellbeingDimension.allCases {
                let data = try JSONEncoder().encode(dimension)
                let decoded = try JSONDecoder().decode(WellbeingDimension.self, from: data)
                XCTAssertEqual(dimension, decoded)
            }
        }

        func test_wellbeingDimension_rawValues_areDistinct() {
            let rawValues = WellbeingDimension.allCases.map(\.rawValue)
            XCTAssertEqual(rawValues.count, Set(rawValues).count)
        }
    }

#endif
