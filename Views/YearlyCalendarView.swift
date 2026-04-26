import SwiftUI

struct YearlyCalendarView: View {
    @StateObject var viewModel: YearlyCalendarViewModel
    @Environment(\.dismiss)
    var dismiss
    @State private var sheetDetent: PresentationDetent = .medium

    private let SHEET_AUTO_EXPAND_THRESHOLD = 3

    var layoutConfig: HeatmapLayoutConfiguration {
        self.viewModel.layoutConfig
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isPortrait = geometry.size.height > geometry.size.width

                ScrollView(self.layoutConfig.gridDirection == .vertical ? .vertical : [.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 16) {
                        self.yearSelector
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)

                        self.heatmapGrid
                            .padding()
                            .background(Color.primary.opacity(0.02))
                            .cornerRadius(12)

                        self.legend
                            .padding(.horizontal)

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
            #if canImport(UIKit)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { self.dismiss() }
                    }
                }
                .sheet(item: self.$viewModel.selectedSnapshot) { snapshot in
                    DayMealPopupView(snapshot: snapshot, selectedDetent: self.$sheetDetent)
                        .presentationDetents([.medium, .large], selection: self.$sheetDetent)
                        .onAppear {
                            self.sheetDetent = snapshot.mealCount >= self.SHEET_AUTO_EXPAND_THRESHOLD ? .large : .medium
                        }
                }
        }
    }

    // MARK: - Year Selector

    private var yearSelector: some View {
        HStack(spacing: 20) {
            Button { self.viewModel.selectedYear -= 1 } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Previous year")

            Text(String(self.viewModel.selectedYear))
                .font(.title.bold())
                .monospacedDigit()

            Button { self.viewModel.selectedYear += 1 } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Next year")
        }
    }

    // MARK: - Heatmap Grid

    @ViewBuilder private var heatmapGrid: some View {
        if self.layoutConfig.gridDirection == .vertical {
            self.portraitGrid
        } else {
            self.landscapeGrid
        }
    }

    private var legend: some View {
        HeatMapLegend()
    }
}

#Preview {
    YearlyCalendarView(viewModel: YearlyCalendarViewModel(historicalService: HistoricalDataService()))
}
