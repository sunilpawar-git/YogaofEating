import SwiftUI

struct YearlyCalendarView: View {
    @StateObject var viewModel: YearlyCalendarViewModel
    @Environment(\.dismiss) var dismiss

    // Grid layout: 7 rows (days of week), 53 columns (weeks of year)
    private let cellSize: CGFloat = 16
    private let spacing: CGFloat = 4

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 20) {
                    // Year Selector
                    HStack(spacing: 12) {
                        Button { self.viewModel.selectedYear -= 1 } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }

                        Text("\(String(self.viewModel.selectedYear))")
                            .font(.title3.bold())
                            .frame(width: 80)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(8)

                        Button { self.viewModel.selectedYear += 1 } label: {
                            Image(systemName: "chevron.right")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)

                    // The Heatmap Grid
                    self.heatmapGrid
                        .padding()
                        .background(Color.primary.opacity(0.02))
                        .cornerRadius(12)

                    // Legend
                    self.legend
                        .padding(.horizontal)

                    // Bottom padding
                    Color.clear.frame(height: 20)
                }
                .padding(.top)
            }
            .navigationTitle("Yearly Smiley Heatmap")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { self.dismiss() }
                }
            }
            .popover(item: self.$viewModel.selectedSnapshot) { snapshot in
                DayMealPopupView(snapshot: snapshot)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var heatmapGrid: some View {
        HStack(alignment: .top, spacing: 8) {
            // Day of week labels
            VStack(alignment: .leading, spacing: 4) {
                Color.clear.frame(height: 12) // Alignment with grid
                Text("Mon").font(.caption2).foregroundColor(.secondary)
                Color.clear.frame(height: 12)
                Text("Wed").font(.caption2).foregroundColor(.secondary)
                Color.clear.frame(height: 12)
                Text("Fri").font(.caption2).foregroundColor(.secondary)
            }

            // Grid of days
            VStack(alignment: .leading, spacing: 4) {
                // Month labels
                HStack(spacing: 0) {
                    ForEach(Array(self.viewModel.monthLabels.enumerated()), id: \.element.id) { index, label in
                        // Calculate width based on weeks until next month (or end of year)
                        let nextOffset: Int = if index < self.viewModel.monthLabels.count - 1 {
                            self.viewModel.monthLabels[index + 1].weekOffset
                        } else {
                            53 // End of year
                        }
                        let weekSpan = max(1, nextOffset - label.weekOffset)
                        let frameWidth = CGFloat(weekSpan) * (self.cellSize + self.spacing)
                        Text(label.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(
                                width: frameWidth,
                                alignment: .leading
                            )
                    }
                }

                LazyHGrid(
                    rows: Array(repeating: GridItem(.fixed(self.cellSize), spacing: self.spacing), count: 7),
                    spacing: self.spacing
                ) {
                    ForEach(self.viewModel.allDates, id: \.self) { date in
                        let snapshot = self.viewModel.snapshots.first {
                            Calendar.current.isDate($0.date, inSameDayAs: date)
                        }

                        DayCell(date: date, snapshot: snapshot)
                            .onTapGesture {
                                if let snapshot {
                                    self.viewModel.selectSnapshot(snapshot)
                                }
                            }
                    }
                }
            }
        }
    }

    private var legend: some View {
        HeatMapLegend()
    }
}

struct HeatMapLegend: View {
    private let cellSize: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                self.legendItem(title: "Serene", color: .green, identifier: "legend-serene")
                    .accessibilityLabel("Serene mood heatmap scale")
                self.legendItem(title: "Neutral", color: .blue, identifier: "legend-neutral")
                    .accessibilityLabel("Neutral mood heatmap scale")
                self.legendItem(title: "Overwhelmed", color: .orange, identifier: "legend-overwhelmed")
                    .accessibilityLabel("Overwhelmed mood heatmap scale")
            }
        }
    }

    private func legendItem(title: String, color: Color, identifier: String) -> some View {
        HStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(0..<4) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.1 + Double(i) * 0.25))
                        .frame(width: self.cellSize, height: self.cellSize)
                }
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .accessibilityIdentifier(identifier)
        }
    }
}

#Preview {
    YearlyCalendarView(viewModel: YearlyCalendarViewModel(historicalService: HistoricalDataService()))
}
