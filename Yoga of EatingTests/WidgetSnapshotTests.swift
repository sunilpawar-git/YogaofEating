import XCTest
@testable import Yoga_of_Eating

final class WidgetSnapshotTests: XCTestCase {
    // MARK: - Codable round-trip

    func testEncodeDecodeRoundTrip() throws {
        let snapshot = WidgetSnapshot(
            overallProgress: 0.75,
            bisScore: 82.5,
            streak: 5,
            date: Date()
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(
            WidgetSnapshot.self, from: data
        )

        XCTAssertEqual(decoded.overallProgress, 0.75, accuracy: 0.001)
        XCTAssertEqual(decoded.bisScore, 82.5, accuracy: 0.001)
        XCTAssertEqual(decoded.streak, 5)
    }

    func testEmptySnapshotValues() {
        let empty = WidgetSnapshot.empty

        XCTAssertEqual(empty.overallProgress, 0)
        XCTAssertEqual(empty.bisScore, 0)
        XCTAssertEqual(empty.streak, 0)
        XCTAssertEqual(empty.date, .distantPast)
    }

    // MARK: - WidgetDataProvider

    func testLoadReturnsEmptyWhenFileAbsent() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        let result = WidgetDataProvider.load(from: tempDir)

        XCTAssertEqual(result, WidgetSnapshot.empty)
    }

    func testLoadReadsWrittenSnapshot() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let snapshot = WidgetSnapshot(
            overallProgress: 0.6,
            bisScore: 55.0,
            streak: 3,
            date: Date()
        )

        let fileURL = tempDir.appendingPathComponent(
            WidgetDataProvider.fileName
        )
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: .atomic)

        let loaded = WidgetDataProvider.load(from: tempDir)

        XCTAssertEqual(loaded.overallProgress, 0.6, accuracy: 0.001)
        XCTAssertEqual(loaded.bisScore, 55.0, accuracy: 0.001)
        XCTAssertEqual(loaded.streak, 3)
    }

    func testLoadReturnsEmptyForCorruptedData() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent(
            WidgetDataProvider.fileName
        )
        try "not valid json".write(
            to: fileURL, atomically: true, encoding: .utf8
        )

        let loaded = WidgetDataProvider.load(from: tempDir)
        XCTAssertEqual(loaded, WidgetSnapshot.empty)
    }

    // MARK: - PersistenceService widget write

    @MainActor
    func testWriteWidgetSnapshotCreatesValidJSON() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let snapshot = WidgetSnapshot(
            overallProgress: 0.8,
            bisScore: 90.0,
            streak: 7,
            date: Date()
        )

        PersistenceService.writeWidgetSnapshot(
            snapshot, to: tempDir
        )

        let fileURL = tempDir.appendingPathComponent(
            WidgetDataProvider.fileName
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let data = try Data(contentsOf: fileURL)
        let decoded = try JSONDecoder().decode(
            WidgetSnapshot.self, from: data
        )
        XCTAssertEqual(decoded.bisScore, 90.0, accuracy: 0.001)
        XCTAssertEqual(decoded.streak, 7)
    }
}
