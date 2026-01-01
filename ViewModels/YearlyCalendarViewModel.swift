import Combine
import Foundation

/// ViewModel for the Yearly Smiley Heatmap Calendar.
/// Manages the state and logic for fetching and displaying daily eating history.
@MainActor
class YearlyCalendarViewModel: ObservableObject {
    // MARK: - Properties

    @Published var selectedYear: Int {
        didSet {
            self.fetchSnapshots()
        }
    }

    @Published private(set) var snapshots: [DailySmileySnapshot] = []
    @Published var selectedSnapshot: DailySmileySnapshot?
    @Published private(set) var allDates: [Date] = []

    struct MonthLabel: Identifiable {
        let id = UUID()
        let name: String
        let weekOffset: Int
    }

    @Published private(set) var monthLabels: [MonthLabel] = []

    private let historicalService: any HistoricalDataServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(historicalService: (any HistoricalDataServiceProtocol)? = nil) {
        self.historicalService = historicalService ?? HistoricalDataService()
        self.selectedYear = Calendar.current.component(.year, from: Date())
        self.fetchSnapshots()
        self.generateYearData()
    }

    // MARK: - Data Fetching

    /// Fetches all available snapshots for the currently selected year.
    func fetchSnapshots() {
        self.snapshots = self.historicalService.getYearSnapshots(year: self.selectedYear)
        self.generateYearData()
    }

    private func generateYearData() {
        let calendar = Calendar.current
        guard let startOfYear = calendar.date(from: DateComponents(year: self.selectedYear, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: self.selectedYear, month: 12, day: 31))
        else {
            return
        }

        var dates: [Date] = []
        var currentDate = startOfYear
        while currentDate <= endOfYear {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        self.allDates = dates

        // Calculate month labels and their week offsets
        var labels: [MonthLabel] = []
        let monthSymbols = calendar.shortMonthSymbols

        for month in 1...12 {
            if let firstOfMonth = calendar.date(from: DateComponents(year: self.selectedYear, month: month, day: 1)) {
                // Calculate how many weeks this date is from the start of the year
                let components = calendar.dateComponents([.weekOfYear], from: startOfYear, to: firstOfMonth)
                let weekOffset = components.weekOfYear ?? 0
                labels.append(MonthLabel(name: monthSymbols[month - 1], weekOffset: weekOffset))
            }
        }
        self.monthLabels = labels
    }

    // MARK: - Interaction

    /// Sets the currently selected snapshot for detailed view.
    func selectSnapshot(_ snapshot: DailySmileySnapshot) {
        self.selectedSnapshot = snapshot
    }
}
