import SwiftUI

struct WeeklySummaryCardView: View {
    let insight: WeeklyInsight
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            self.onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.purple)
                    Text(Strings.Insight.weeklyTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(self.insight.formattedDateRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(self.insight.summaryText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                if !self.insight.wins.isEmpty {
                    Text("\(Strings.Insight.weeklyWinPrefix): \(self.insight.wins.first ?? "")")
                        .font(.caption)
                        .foregroundColor(.green)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.purple.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct WeeklySummaryView: View {
    let insight: WeeklyInsight
    var archetype: EnergyArchetype?
    var isPremium: Bool = false
    var bisAverage: Double = 0
    /// Called to generate the PDF; returns the URL or nil on failure.
    var onExport: () -> URL?
    @State private var exportURL: URL?
    @State private var showExportError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(Strings.Insight.weeklyTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(self.insight.formattedDateRange)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(self.insight.summaryText)
                    .font(.body)

                if let archetype {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk.motion")
                            .foregroundColor(.purple)
                        Text("\(Strings.Trends.archetypePrefix): \(archetype.displayName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if !self.insight.wins.isEmpty {
                    self.section(title: Strings.Insight.weeklyWinsTitle, items: self.insight.wins, color: .green)
                }
                if !self.insight.improvementAreas.isEmpty {
                    self.section(
                        title: Strings.Insight.weeklyImprovementsTitle,
                        items: self.insight.improvementAreas,
                        color: .orange
                    )
                }

                if self.isPremium {
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label(Strings.Premium.exportPdf, systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            if let url = self.onExport() {
                                self.exportURL = url
                            } else {
                                self.showExportError = true
                            }
                        } label: {
                            Label(Strings.Premium.exportPdf, systemImage: "doc.richtext")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
        }
        .alert(Strings.Premium.exportFailed, isPresented: self.$showExportError) {
            Button(Strings.Common.done, role: .cancel) {}
        }
    }

    private func section(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
