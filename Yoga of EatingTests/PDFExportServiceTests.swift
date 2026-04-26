import XCTest
@testable import Yoga_of_Eating

final class PDFExportServiceTests: XCTestCase {
    func test_exportWeeklySummary_createsPdfFile() throws {
        let insight = WeeklyInsight(
            weekStartDate: Date(),
            weekEndDate: Date(),
            summaryText: "Solid progress.",
            improvementAreas: ["Sleep earlier"],
            wins: ["Consistent meals"]
        )
        let url = try PDFExportService.exportWeeklySummary(
            insight: insight,
            archetype: .steadyState,
            bisAverage: 78
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[FileAttributeKey.size] as? NSNumber
        XCTAssertNotNil(fileSize)
        XCTAssertGreaterThan(fileSize?.intValue ?? 0, 0)
    }
}
