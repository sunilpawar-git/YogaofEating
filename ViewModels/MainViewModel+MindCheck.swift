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
        self.editingMorningEntries = nil
    }

    /// Handles dismissal of morning mind check input without saving.
    func dismissMorningMindCheckInput() {
        self.showMorningMindCheckSheet = false
        self.editingMorningEntries = nil
    }

    /// Handles completion of evening mind check input.
    /// - Parameter entries: The entered mind check entries
    func completeEveningMindCheckInput(_ entries: [MindCheckEntry]) {
        self.saveEveningMindCheck(entries)
        self.showEveningMindCheckSheet = false
        self.editingEveningEntries = nil
    }

    /// Handles completion of evening review (with morning todo updates).
    /// Phase 3: Now also accepts feeling for holistic End-of-Day capture.
    /// - Parameters:
    ///   - updatedMorningEntries: Morning entries with accomplished status updated
    ///   - eveningEntries: New evening entries (gratitude, let go)
    ///   - feeling: Optional overall feeling (for End-of-Day flow)
    func completeEveningReview(
        updatedMorningEntries: [MindCheckEntry],
        eveningEntries: [MindCheckEntry],
        feeling: ReflectionFeeling? = nil
    ) {
        // Update morning entries with accomplished status
        self.saveMorningMindCheck(updatedMorningEntries)

        // Save evening entries
        self.saveEveningMindCheck(eveningEntries)

        // Save feeling if provided (Phase 3: holistic End-of-Day)
        if let feeling {
            self.saveOverallFeeling(feeling)
        }

        self.showEveningMindCheckSheet = false
        self.editingEveningEntries = nil
        self.isEndOfDayFlow = false // Reset flag
    }

    /// Handles dismissal of evening mind check input without saving.
    func dismissEveningMindCheckInput() {
        self.showEveningMindCheckSheet = false
        self.editingEveningEntries = nil
        self.isEndOfDayFlow = false // Reset flag
    }

    // MARK: - Edit Methods

    /// Opens the morning mind check sheet in edit mode with existing entries.
    /// - Parameter entries: The existing entries to edit
    func editMorningMindCheck(_ entries: [MindCheckEntry]) {
        self.editingMorningEntries = entries
        self.showMorningMindCheckSheet = true
    }

    /// Opens the evening mind check sheet in edit mode with existing entries.
    /// - Parameter entries: The existing entries to edit
    func editEveningMindCheck(_ entries: [MindCheckEntry]) {
        self.editingEveningEntries = entries
        self.showEveningMindCheckSheet = true
    }
}
