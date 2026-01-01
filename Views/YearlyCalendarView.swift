import SwiftUI

struct YearlyCalendarView: View {
    @StateObject var viewModel: YearlyCalendarViewModel
    @Environment(\.dismiss) var dismiss

    // Grid layout: 7 rows (days of week), 53 columns (weeks of year)
    private let columns = Array(repeating: GridItem(.fixed(12), spacing: 4), count: 53)

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 20) {
                    // Year Selector
                    HStack {
                        Button { self.viewModel.selectedYear -= 1 } label: {
                            Image(systemName: "chevron.left")
                        }

                        Text("\(String(self.viewModel.selectedYear))")
                            .font(.title2.bold())
                            .frame(width: 100)

                        Button { self.viewModel.selectedYear += 1 } label: {
                            Image(systemName: "chevron.right")
                        }

                        Spacer()
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

                    Spacer()
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
                Spacer().frame(height: 12) // Alignment with grid
                Text("Mon").font(.caption2).foregroundColor(.secondary)
                Spacer().frame(height: 12)
                Text("Wed").font(.caption2).foregroundColor(.secondary)
                Spacer().frame(height: 12)
                Text("Fri").font(.caption2).foregroundColor(.secondary)
            }

            // Grid of days
            VStack(alignment: .leading, spacing: 4) {
                // Month labels
                HStack(spacing: 0) {
                    ForEach(0..<12) { month in
                        Text(Calendar.current.shortMonthSymbols[month])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: (53.0 / 12.0) * 16, alignment: .leading)
                    }
                }

                LazyHGrid(rows: Array(repeating: GridItem(.fixed(12), spacing: 4), count: 7), spacing: 4) {
                    ForEach(self.allDaysInYear(), id: \.self) { date in
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
        HStack(spacing: 12) {
            Text("Less").font(.caption).foregroundColor(.secondary)
            DayCell(date: Date(), snapshot: nil).frame(width: 12)
            Color.green.opacity(0.3).frame(width: 12, height: 12).cornerRadius(2)
            Color.green.opacity(0.6).frame(width: 12, height: 12).cornerRadius(2)
            Color.green.opacity(0.9).frame(width: 12, height: 12).cornerRadius(2)
            Text("More").font(.caption).foregroundColor(.secondary)
        }
    }

    private func allDaysInYear() -> [Date] {
        let calendar = Calendar.current
        guard let startOfYear = calendar.date(from: DateComponents(
            year: self.viewModel.selectedYear,
            month: 1,
            day: 1
        )),
            let endOfYear = calendar
            .date(from: DateComponents(year: self.viewModel.selectedYear, month: 12, day: 31))
        else {
            return []
        }

        var dates: [Date] = []
        var currentDate = startOfYear

        while currentDate <= endOfYear {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return dates
    }
}

#Preview {
    YearlyCalendarView(viewModel: YearlyCalendarViewModel(historicalService: HistoricalDataService()))
}
