import Foundation

// MARK: - PDF Export Extension

extension MainViewModel {
    /// Generates and returns a PDF URL for the given weekly insight.
    func exportWeeklyPDF(
        insight: WeeklyInsight,
        archetype: EnergyArchetype?,
        bisAverage: Double
    ) -> URL? {
        try? PDFExportService.exportWeeklySummary(
            insight: insight,
            archetype: archetype,
            bisAverage: bisAverage
        )
    }
}
