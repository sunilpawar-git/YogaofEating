import SwiftUI

struct YearlyCalendarView: View {
    @StateObject var viewModel: YearlyCalendarViewModel
    @Environment(\.dismiss) var dismiss

    /// Convenience computed property to access current layout config
    private var layoutConfig: HeatmapLayoutConfiguration {
        self.viewModel.layoutConfig
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isPortrait = geometry.size.height > geometry.size.width

                ScrollView(self.layoutConfig.gridDirection == .vertical ? .vertical : [.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Year Selector at top of scroll content
                        self.yearSelector
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)

                        // The Heatmap Grid
                        self.heatmapGrid
                            .padding()
                            .background(Color.primary.opacity(0.02))
                            .cornerRadius(12)

                        // Legend at bottom
                        self.legend
                            .padding(.horizontal)

                        // Bottom padding for safe area
                        Color.clear.frame(height: 20)
                    }
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
            .navigationTitle("Yearly Heatmap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { self.dismiss() }
                }
            }
            .sheet(item: self.$viewModel.selectedSnapshot) { snapshot in
                DayMealPopupView(snapshot: snapshot)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Year Selector

    private var yearSelector: some View {
        HStack(spacing: 20) {
            // Previous year button with larger tap target
            Button { self.viewModel.selectedYear -= 1 } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44) // Apple HIG minimum
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Previous year")

            // Current year display
            Text(String(self.viewModel.selectedYear))
                .font(.title.bold())
                .monospacedDigit()

            // Next year button with larger tap target
            Button { self.viewModel.selectedYear += 1 } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44) // Apple HIG minimum
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Next year")
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
                            // Show popup for any day - create empty snapshot if needed
                            let snapshotToShow = snapshot ?? self.createEmptySnapshot(for: date)
                            self.viewModel.selectSnapshot(snapshotToShow)
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
                            // Show popup for any day - create empty snapshot if needed
                            let snapshotToShow = snapshot ?? self.createEmptySnapshot(for: date)
                            self.viewModel.selectSnapshot(snapshotToShow)
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

    // MARK: - Helpers

    /// Creates an empty snapshot for days without data so popup can still show.
    private func createEmptySnapshot(for date: Date) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: UUID(),
            date: date,
            smileyState: SmileyState(scale: 0.5, mood: .neutral),
            meals: [],
            mealCount: 0,
            averageHealthScore: 0
        )
    }
}

struct HeatMapLegend: View {
    private let cellSize: CGFloat = 14
    private let cornerRadius: CGFloat = 3

    /// Base opacity matching DayCell
    private let baseOpacity: Double = 0.25
    private let opacityRange: Double = 0.6

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Legend")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            HStack(spacing: 20) {
                self.legendItem(title: "Serene", color: .green, identifier: "legend-serene")
                    .accessibilityLabel("Serene mood: green colors indicate calm, balanced eating")
                self.legendItem(title: "Neutral", color: .blue, identifier: "legend-neutral")
                    .accessibilityLabel("Neutral mood: blue colors indicate typical eating")
                self.legendItem(title: "Overwhelmed", color: .orange, identifier: "legend-overwhelmed")
                    .accessibilityLabel("Overwhelmed mood: orange colors indicate stress eating")
            }

            // Empty cell indicator
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: self.cornerRadius)
                    .fill(Color.primary.opacity(0.03))
                    .frame(width: self.cellSize, height: self.cellSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: self.cornerRadius)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func legendItem(title: String, color: Color, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                // Show 4 intensity levels matching actual cell opacity calculation
                ForEach(0..<4) { i in
                    let score = Double(i) / 3.0 // 0, 0.33, 0.66, 1.0
                    let opacity = self.baseOpacity + (score * self.opacityRange)
                    RoundedRectangle(cornerRadius: self.cornerRadius)
                        .fill(color.opacity(opacity))
                        .frame(width: self.cellSize, height: self.cellSize)
                        .overlay(
                            RoundedRectangle(cornerRadius: self.cornerRadius)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                }
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityIdentifier(identifier)
        }
    }
}

#Preview {
    YearlyCalendarView(viewModel: YearlyCalendarViewModel(historicalService: HistoricalDataService()))
}
