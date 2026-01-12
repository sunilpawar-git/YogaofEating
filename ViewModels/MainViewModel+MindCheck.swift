import Foundation
import SwiftUI

// MARK: - Mind Check Extension

extension MainViewModel {
    // MARK: - Computed Properties

    /// Returns true if the morning mind check pill should be shown.
    /// Shows when: sleep quality is logged AND morning mind check is not yet logged.
    var showMorningMindCheckPill: Bool {
        // Must have sleep quality logged
        guard self.todaysSleepQuality != nil else { return false }

        // Must not have morning mind check logged
        guard self.todaysMorningMindCheck == nil else { return false }

        return true
    }

    /// Returns true if the evening mind check pill should be shown.
    /// Shows when: at least one meal exists AND evening mind check is not yet logged.
    var showEveningMindCheckPill: Bool {
        // Must have at least one meal
        guard !self.meals.isEmpty else { return false }

        // Must not have evening mind check logged
        guard self.todaysEveningMindCheck == nil else { return false }

        return true
    }

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
    /// - Parameter entries: The mind check entries to save
    func saveMorningMindCheck(_ entries: [MindCheckEntry]) {
        let today = Date()
        self.historicalService.updateMorningMindCheck(for: today, entries: entries)
        self.saveData()
    }

    /// Saves evening mind check entries for today.
    /// - Parameter entries: The mind check entries to save
    func saveEveningMindCheck(_ entries: [MindCheckEntry]) {
        let today = Date()
        self.historicalService.updateEveningMindCheck(for: today, entries: entries)
        self.saveData()
    }

    // MARK: - Sheet Handlers

    /// Handles completion of morning mind check input.
    /// - Parameter entries: The entered mind check entries
    func completeMorningMindCheckInput(_ entries: [MindCheckEntry]) {
        self.saveMorningMindCheck(entries)
        self.showMorningMindCheckSheet = false
    }

    /// Handles dismissal of morning mind check input without saving.
    func dismissMorningMindCheckInput() {
        self.showMorningMindCheckSheet = false
    }

    /// Handles completion of evening mind check input.
    /// - Parameter entries: The entered mind check entries
    func completeEveningMindCheckInput(_ entries: [MindCheckEntry]) {
        self.saveEveningMindCheck(entries)
        self.showEveningMindCheckSheet = false
    }

    /// Handles dismissal of evening mind check input without saving.
    func dismissEveningMindCheckInput() {
        self.showEveningMindCheckSheet = false
    }
}
