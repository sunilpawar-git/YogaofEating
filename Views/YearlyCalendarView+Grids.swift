import SwiftUI

extension YearlyCalendarView {
    var dayOfWeekLabels: [String] {
        ["M", "T", "W", "T", "F", "S", "S"]
    }

    var portraitGrid: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .trailing, spacing: 0) {
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
                HStack(spacing: self.layoutConfig.spacing) {
                    ForEach(self.dayOfWeekLabels, id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: self.layoutConfig.cellSize)
                    }
                }

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.fixed(self.layoutConfig.cellSize), spacing: self.layoutConfig.spacing),
                        count: 7
                    ),
                    spacing: self.layoutConfig.spacing
                ) {
                    ForEach(self.viewModel.allCells) { cell in
                        if let date = cell.date {
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
                                let snapshotToShow = snapshot ?? self.createEmptySnapshot(for: date)
                                self.viewModel.selectSnapshot(snapshotToShow)
                            }
                        } else {
                            Color.clear
                                .frame(width: self.layoutConfig.cellSize, height: self.layoutConfig.cellSize)
                        }
                    }
                }
            }
        }
    }

    var landscapeGrid: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: self.layoutConfig.spacing) {
                Color.clear.frame(height: 16)
                ForEach(Array(self.dayOfWeekLabels.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(height: self.layoutConfig.cellSize)
                }
            }

            VStack(alignment: .leading, spacing: self.layoutConfig.spacing) {
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

                LazyHGrid(
                    rows: Array(
                        repeating: GridItem(.fixed(self.layoutConfig.cellSize), spacing: self.layoutConfig.spacing),
                        count: 7
                    ),
                    spacing: self.layoutConfig.spacing
                ) {
                    ForEach(self.viewModel.allCells) { cell in
                        if let date = cell.date {
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
                                let snapshotToShow = snapshot ?? self.createEmptySnapshot(for: date)
                                self.viewModel.selectSnapshot(snapshotToShow)
                            }
                        } else {
                            Color.clear
                                .frame(width: self.layoutConfig.cellSize, height: self.layoutConfig.cellSize)
                        }
                    }
                }
            }
        }
    }

    func createEmptySnapshot(for date: Date) -> DailySmileySnapshot {
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
