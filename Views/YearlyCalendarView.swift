import SwiftUI

struct YearlyCalendarView: View {
    @StateObject var viewModel: YearlyCalendarViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    /// Convenience computed property to access current layout config
    private var layoutConfig: HeatmapLayoutConfiguration {
        self.viewModel.layoutConfig
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isPortrait = geometry.size.height > geometry.size.width

                ScrollView(self.layoutConfig.gridDirection == .vertical ? .vertical : [.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Year Selector
                        self.yearSelector
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
                .onChange(of: geometry.size) { _, newSize in
                    self.viewModel.updateLayout(
                        screenWidth: newSize.width,
                        screenHeight: newSize.height,
                        isPortrait: newSize.height > newSize.width
                    )
                }
                .onAppear {
                    self.viewModel.updateLayout(
                        screenWidth: geometry.size.width,
                        screenHeight: geometry.size.height,
                        isPortrait: isPortrait
                    )
                }
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

    // MARK: - Year Selector

    private var yearSelector: some View {
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
    }

    // MARK: - Heatmap Grid

    @ViewBuilder
    private var heatmapGrid: some View {
        if self.layoutConfig.gridDirection == .vertical {
            self.portraitGrid
        } else {
            self.landscapeGrid
        }
    }

    /// Portrait mode: 7 columns (Mon-Sun), rows for weeks
    private var portraitGrid: some View {
        HStack(alignment: .top, spacing: 8) {
            // Month labels on left side for portrait
            VStack(alignment: .trailing, spacing: 0) {
                // Spacer for day labels row
                Color.clear.frame(height: 20)

                ForEach(Array(self.viewModel.monthLabels.enumerated()), id: \.element.id) { index, label in
                    let nextOffset: Int = if index < self.viewModel.monthLabels.count - 1 {
                        self.viewModel.monthLabels[index + 1].weekOffset
                    } else {
                        53
                    }
                    let weekSpan = max(1, nextOffset - label.weekOffset)
                    let frameHeight = CGFloat(weekSpan) * (layoutConfig.cellSize + self.layoutConfig.spacing)

                    Text(label.name)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(height: frameHeight, alignment: .top)
                }
            }
            .frame(width: 30)

            VStack(alignment: .leading, spacing: self.layoutConfig.spacing) {
                // Day of week labels on top
                HStack(spacing: self.layoutConfig.spacing) {
                    ForEach(self.dayOfWeekLabels, id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: self.layoutConfig.cellSize)
                    }
                }

                // Grid: 7 columns (days), 53 rows (weeks)
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.fixed(self.layoutConfig.cellSize), spacing: self.layoutConfig.spacing),
                        count: 7
                    ),
                    spacing: self.layoutConfig.spacing
                ) {
                    ForEach(self.viewModel.allDates, id: \.self) { date in
                        let snapshot = self.viewModel.snapshots.first {
                            Calendar.current.isDate($0.date, inSameDayAs: date)
                        }

                        DayCell(
                            date: date,
                            snapshot: snapshot,
                            cellSize: self.layoutConfig.cellSize,
                            cornerRadius: self.layoutConfig.cornerRadius
                        )
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

    /// Landscape mode: 7 rows (days), columns for weeks (original layout)
    private var landscapeGrid: some View {
        HStack(alignment: .top, spacing: 8) {
            // Day of week labels on left
            VStack(alignment: .leading, spacing: self.layoutConfig.spacing) {
                Color.clear.frame(height: 16) // Alignment with month labels
                ForEach(Array(self.dayOfWeekLabels.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(height: self.layoutConfig.cellSize)
                }
            }

            // Grid of days
            VStack(alignment: .leading, spacing: self.layoutConfig.spacing) {
                // Month labels on top
                HStack(spacing: 0) {
                    ForEach(Array(self.viewModel.monthLabels.enumerated()), id: \.element.id) { index, label in
                        let nextOffset: Int = if index < self.viewModel.monthLabels.count - 1 {
                            self.viewModel.monthLabels[index + 1].weekOffset
                        } else {
                            53
                        }
                        let weekSpan = max(1, nextOffset - label.weekOffset)
                        let frameWidth = CGFloat(weekSpan) * (layoutConfig.cellSize + self.layoutConfig.spacing)

                        Text(label.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: frameWidth, alignment: .leading)
                    }
                }

                // Grid: 7 rows (days), 53 columns (weeks)
                LazyHGrid(
                    rows: Array(
                        repeating: GridItem(.fixed(self.layoutConfig.cellSize), spacing: self.layoutConfig.spacing),
                        count: 7
                    ),
                    spacing: self.layoutConfig.spacing
                ) {
                    ForEach(self.viewModel.allDates, id: \.self) { date in
                        let snapshot = self.viewModel.snapshots.first {
                            Calendar.current.isDate($0.date, inSameDayAs: date)
                        }

                        DayCell(
                            date: date,
                            snapshot: snapshot,
                            cellSize: self.layoutConfig.cellSize,
                            cornerRadius: self.layoutConfig.cornerRadius
                        )
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

    /// Day of week labels (short format)
    private var dayOfWeekLabels: [String] {
        ["M", "T", "W", "T", "F", "S", "S"]
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
