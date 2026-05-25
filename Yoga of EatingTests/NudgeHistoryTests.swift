import XCTest
@testable import Yoga_of_Eating

final class NudgeHistoryTests: XCTestCase {
    func test_nudgeHistoryEntry_encodesAndDecodesCorrectly() throws {
        let entry = NudgeHistoryEntry(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789012")!,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            suggestion: "Drink more water"
        )
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(NudgeHistoryEntry.self, from: data)
        XCTAssertEqual(decoded.id, entry.id)
        XCTAssertEqual(decoded.suggestion, entry.suggestion)
        XCTAssertNil(decoded.wasFollowedThrough)
    }

    func test_nudgeHistoryEntry_wasFollowedThrough_isNilByDefault() {
        let entry = NudgeHistoryEntry(
            id: UUID(),
            date: Date(),
            suggestion: "Try a morning walk"
        )
        XCTAssertNil(entry.wasFollowedThrough)
    }

    func test_nudgeHistory_cappedAt14Entries_oldestDroppedFirst() {
        let entries = (0..<15).map { index in
            NudgeHistoryEntry(
                id: UUID(),
                date: Date(timeIntervalSince1970: Double(index) * 86400),
                suggestion: "Nudge \(index)"
            )
        }
        let capped = Array(entries.suffix(ValidationLimits.nudgeHistoryMaxEntries))
        XCTAssertEqual(capped.count, ValidationLimits.nudgeHistoryMaxEntries)
        XCTAssertEqual(capped.first?.suggestion, "Nudge 1")
        XCTAssertEqual(capped.last?.suggestion, "Nudge 14")
    }
}
