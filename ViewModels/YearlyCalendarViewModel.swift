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

    private let historicalService: any HistoricalDataServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(historicalService: (any HistoricalDataServiceProtocol)? = nil) {
        self.historicalService = historicalService ?? HistoricalDataService()
        self.selectedYear = Calendar.current.component(.year, from: Date())
        self.fetchSnapshots()
    }

    // MARK: - Data Fetching

    /// Fetches all available snapshots for the currently selected year.
    func fetchSnapshots() {
        self.snapshots = self.historicalService.getYearSnapshots(year: self.selectedYear)
    }

    // MARK: - Interaction

    /// Sets the currently selected snapshot for detailed view.
    func selectSnapshot(_ snapshot: DailySmileySnapshot) {
        self.selectedSnapshot = snapshot
    }
}
