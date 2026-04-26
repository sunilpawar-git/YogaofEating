import Foundation

#if canImport(UIKit)
    import UIKit
#endif

// MARK: - Layout constants

private enum PDFLayout {
    static let pageWidth: CGFloat = 612
    static let pageHeight: CGFloat = 792
    static let margin: CGFloat = 40
    static let contentWidth: CGFloat = 530
    static let titleY: CGFloat = 40
    static let dateRangeY: CGFloat = 72
    static let bisY: CGFloat = 96
    static let archetypeY: CGFloat = 120
    static let summaryY: CGFloat = 160
    static let summaryHeight: CGFloat = 120
    static let bodyStartY: CGFloat = 300
    static let lineSpacing: CGFloat = 22
    static let sectionGap: CGFloat = 20
    static let titleFontSize: CGFloat = 22
    static let bodyFontSize: CGFloat = 14
}

enum PDFExportService {
    // swiftlint:disable function_body_length
    static func exportWeeklySummary(
        insight: WeeklyInsight,
        archetype: EnergyArchetype?,
        bisAverage: Double
    ) throws -> URL {
        #if canImport(UIKit)
            let bounds = CGRect(x: 0, y: 0, width: PDFLayout.pageWidth, height: PDFLayout.pageHeight)
            let renderer = UIGraphicsPDFRenderer(bounds: bounds)
            let data = renderer.pdfData { context in
                context.beginPage()
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: PDFLayout.titleFontSize)
                ]
                let bodyAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: PDFLayout.bodyFontSize)
                ]

                NSString(string: Strings.Insight.weeklyTitle)
                    .draw(at: CGPoint(x: PDFLayout.margin, y: PDFLayout.titleY), withAttributes: titleAttrs)
                NSString(string: insight.formattedDateRange)
                    .draw(at: CGPoint(x: PDFLayout.margin, y: PDFLayout.dateRangeY), withAttributes: bodyAttrs)
                NSString(string: Strings.BIS.avgLabel(Int(bisAverage)))
                    .draw(at: CGPoint(x: PDFLayout.margin, y: PDFLayout.bisY), withAttributes: bodyAttrs)
                if let archetype {
                    NSString(string: "\(Strings.Trends.archetypePrefix): \(archetype.displayName)")
                        .draw(at: CGPoint(x: PDFLayout.margin, y: PDFLayout.archetypeY), withAttributes: bodyAttrs)
                }
                NSString(string: insight.summaryText)
                    .draw(
                        in: CGRect(
                            x: PDFLayout.margin,
                            y: PDFLayout.summaryY,
                            width: PDFLayout.contentWidth,
                            height: PDFLayout.summaryHeight
                        ),
                        withAttributes: bodyAttrs
                    )

                var yPos = PDFLayout.bodyStartY
                for win in insight.wins.prefix(4) {
                    NSString(string: "• \(win)")
                        .draw(at: CGPoint(x: PDFLayout.margin, y: yPos), withAttributes: bodyAttrs)
                    yPos += PDFLayout.lineSpacing
                }
                yPos += PDFLayout.sectionGap
                for area in insight.improvementAreas.prefix(4) {
                    NSString(string: "• \(area)")
                        .draw(at: CGPoint(x: PDFLayout.margin, y: yPos), withAttributes: bodyAttrs)
                    yPos += PDFLayout.lineSpacing
                }
            }

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("WeeklySummary-\(UUID().uuidString).pdf")
            try data.write(to: url)
            return url
        #else
            throw NSError(
                domain: "PDFExport",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "PDF export unavailable"]
            )
        #endif
    }
    // swiftlint:enable function_body_length
}
