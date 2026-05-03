import Foundation

/// Protocol exposing the minimal surface of MainViewModel that HistoricalDataService
/// needs to delegate persistence back to the authoritative save path.
///
/// Using this protocol instead of a concrete `MainViewModel` reference removes the DIP
/// violation that previously existed in MainViewModel.init() (the `as? HistoricalDataService`
/// back-reference cast). Any future view model conforming to this protocol works without
/// changes to HistoricalDataService.
@MainActor
protocol MainViewModelProtocol: AnyObject {
    /// Saves the current authoritative state (meals, smiley, resetDate, historicalData)
    /// to the persistence layer. Called by HistoricalDataService.saveHistoricalData()
    /// so that the single canonical save path is always used.
    func saveData()
}
