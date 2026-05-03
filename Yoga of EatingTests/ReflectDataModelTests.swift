import XCTest
@testable import Yoga_of_Eating

final class ReflectDataModelTests: XCTestCase {
    func test_defaultInit_hasNoContent() {
        let data = ReflectData()
        XCTAssertNil(data.journalText)
        XCTAssertNil(data.feeling)
        XCTAssertFalse(data.hasContent)
        XCTAssertFalse(data.hasFeelingLogged)
    }

    func test_hasContent_trueWhenJournalTextSet() {
        let data = ReflectData(journalText: "Today was productive")
        XCTAssertTrue(data.hasContent)
    }

    func test_hasContent_trueWhenFeelingSet() {
        let data = ReflectData(feeling: .calm)
        XCTAssertTrue(data.hasContent)
        XCTAssertTrue(data.hasFeelingLogged)
    }

    func test_hasContent_falseForWhitespaceOnlyText() {
        let data = ReflectData(journalText: "   \n  ")
        XCTAssertFalse(data.hasContent)
    }

    func test_encodeDecode_roundTrip() throws {
        let original = ReflectData(
            journalText: "Learned a lot today",
            feeling: .great
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ReflectData.self, from: data)

        XCTAssertEqual(decoded.journalText, original.journalText)
        XCTAssertEqual(decoded.feeling, original.feeling)
    }

    func test_encodeDecode_nilFieldsRoundTrip() throws {
        let original = ReflectData()

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ReflectData.self, from: data)

        XCTAssertNil(decoded.journalText)
        XCTAssertNil(decoded.feeling)
    }

    func test_equatable() {
        let fixedDate = Date(timeIntervalSince1970: 1_000_000)
        let a = ReflectData(journalText: "Good day", feeling: .calm, lastModified: fixedDate)
        let b = ReflectData(journalText: "Good day", feeling: .calm, lastModified: fixedDate)
        let c = ReflectData(journalText: "Good day", feeling: .heavy, lastModified: fixedDate)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
