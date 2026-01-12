import Foundation

/// Protocol for mind check operations to enable testing.
@MainActor
protocol MindCheckServiceProtocol {
    func saveMorningMindCheck(_ entries: [MindCheckEntry], for date: Date)
    func saveEveningMindCheck(_ entries: [MindCheckEntry], for date: Date)
    func getMorningMindCheck(for date: Date) -> [MindCheckEntry]?
    func getEveningMindCheck(for date: Date) -> [MindCheckEntry]?
    func hasMorningMindCheckForToday() -> Bool
    func hasEveningMindCheckForToday() -> Bool
}

/// Service for managing mind check entries (morning and evening reflections).
/// Persists data through the HistoricalDataService.
@MainActor
class MindCheckService: MindCheckServiceProtocol {
    // MARK: - Properties

    private let historicalService: any HistoricalDataServiceProtocol

    // MARK: - Initialization

    init(historicalService: any HistoricalDataServiceProtocol) {
        self.historicalService = historicalService
    }

    // MARK: - Save Methods

    /// Saves morning mind check entries for a specific date.
    /// - Parameters:
    ///   - entries: The mind check entries to save
    ///   - date: The date to save for
    func saveMorningMindCheck(_ entries: [MindCheckEntry], for date: Date) {
        self.historicalService.updateMorningMindCheck(for: date, entries: entries)
    }

    /// Saves evening mind check entries for a specific date.
    /// - Parameters:
    ///   - entries: The mind check entries to save
    ///   - date: The date to save for
    func saveEveningMindCheck(_ entries: [MindCheckEntry], for date: Date) {
        self.historicalService.updateEveningMindCheck(for: date, entries: entries)
    }

    // MARK: - Get Methods

    /// Gets morning mind check entries for a specific date.
    /// - Parameter date: The date to get entries for
    /// - Returns: The entries if logged, nil otherwise
    func getMorningMindCheck(for date: Date) -> [MindCheckEntry]? {
        let snapshot = self.historicalService.getSnapshot(for: date)
        return snapshot?.morningMindCheck
    }

    /// Gets evening mind check entries for a specific date.
    /// - Parameter date: The date to get entries for
    /// - Returns: The entries if logged, nil otherwise
    func getEveningMindCheck(for date: Date) -> [MindCheckEntry]? {
        let snapshot = self.historicalService.getSnapshot(for: date)
        return snapshot?.eveningMindCheck
    }

    // MARK: - Check Methods

    /// Returns true if morning mind check has been logged for today.
    func hasMorningMindCheckForToday() -> Bool {
        let today = Date()
        let snapshot = self.historicalService.getSnapshot(for: today)
        return snapshot?.hasMorningMindCheck ?? false
    }

    /// Returns true if evening mind check has been logged for today.
    func hasEveningMindCheckForToday() -> Bool {
        let today = Date()
        let snapshot = self.historicalService.getSnapshot(for: today)
        return snapshot?.hasEveningMindCheck ?? false
    }
}
