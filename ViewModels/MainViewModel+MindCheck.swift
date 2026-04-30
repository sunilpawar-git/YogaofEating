import Foundation

// MARK: - Mind Check Extension

extension MainViewModel {
    // MARK: - Computed Properties

    /// Returns today's morning mind check entries if logged.
    var todaysMorningMindCheck: [MindCheckEntry]? {
        let today = Date()
        return self.historicalService.getSnapshot(for: today)?.morningMindCheck
    }

    /// Returns today's evening mind check entries if logged.
    var todaysEveningMindCheck: [MindCheckEntry]? {
        let today = Date()
        return self.historicalService.getSnapshot(for: today)?.eveningMindCheck
    }

    // MARK: - Save Methods

    /// Saves morning mind check entries for today.
    func saveMorningMindCheck(_ entries: [MindCheckEntry]) {
        let today = Date()
        self.historicalService.updateMorningMindCheck(for: today, entries: entries)
        self.saveData()
    }

    /// Saves evening mind check entries for today.
    func saveEveningMindCheck(_ entries: [MindCheckEntry]) {
        let today = Date()
        self.historicalService.updateEveningMindCheck(for: today, entries: entries)
        self.saveData()
    }
}
