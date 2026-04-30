import Foundation

// MARK: - Highlight Tab Extension

extension MainViewModel {
    // MARK: - Read Helpers

    /// Returns today's HighlightData, creating a default if none exists.
    private func currentOrNewHighlightData() -> HighlightData {
        self.currentHighlightData ?? HighlightData()
    }

    // MARK: - Update Methods (Auto-Save)

    /// Updates sleep quality in Highlight and persists.
    func updateHighlightSleepQuality(_ quality: SleepQuality?) {
        guard self.isViewingToday else { return }
        var data = self.currentOrNewHighlightData()
        data.sleepQuality = quality
        data.lastModified = Date()
        self.historicalService.updateHighlightData(for: self.selectedDate, data: data)

        // Mirror to legacy reflection so the insight pipeline can read it.
        // Always write (even nil) so the two stores stay in sync.
        self.syncSleepQualityToLegacyReflection(quality, at: self.selectedDate)

        // Fetch Apple sleep data for badge display
        if self.appleSleepData == nil {
            self.fetchAppleSleepDataForHighlight()
        }
    }

    /// Updates sleep notes in Highlight and persists.
    func updateHighlightSleepNotes(_ notes: String) {
        guard self.isViewingToday else { return }
        var data = self.currentOrNewHighlightData()
        data.sleepNotes = notes.isEmpty ? nil : notes
        data.lastModified = Date()
        self.historicalService.updateHighlightData(for: self.selectedDate, data: data)
    }

    /// Updates the full to-do list in Highlight and persists.
    func updateHighlightTodos(_ todos: [MindCheckEntry]) {
        guard self.isViewingToday else { return }
        var data = self.currentOrNewHighlightData()
        data.todos = todos
        data.lastModified = Date()
        self.historicalService.updateHighlightData(for: self.selectedDate, data: data)
    }

    /// Adds a new to-do item and persists.
    func addHighlightTodo(_ text: String) {
        guard self.isViewingToday else { return }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var data = self.currentOrNewHighlightData()
        let entry = MindCheckEntry(
            category: .todo,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            context: .morning
        )
        data.todos.append(entry)
        data.lastModified = Date()
        self.historicalService.updateHighlightData(for: self.selectedDate, data: data)
    }

    /// Removes a to-do item by ID and persists.
    func removeHighlightTodo(_ id: UUID) {
        guard self.isViewingToday else { return }
        var data = self.currentOrNewHighlightData()
        data.todos.removeAll { $0.id == id }
        data.lastModified = Date()
        self.historicalService.updateHighlightData(for: self.selectedDate, data: data)
    }

    /// Updates morning thoughts free-form text and persists.
    func updateHighlightMorningThoughts(_ thoughts: String) {
        guard self.isViewingToday else { return }
        var data = self.currentOrNewHighlightData()
        data.morningThoughts = thoughts.isEmpty ? nil : thoughts
        data.lastModified = Date()
        self.historicalService.updateHighlightData(for: self.selectedDate, data: data)
    }

    // MARK: - Private Helpers

    /// Syncs the sleep quality (or its absence) to the legacy DailyReflection store
    /// so the insight pipeline stays consistent with HighlightData.
    ///
    /// When quality is non-nil, delegates to `saveSleepQuality` which handles merging
    /// and insight generation. When quality is nil (clearing), writes directly to clear
    /// the sleep quality field while preserving the feeling field.
    private func syncSleepQualityToLegacyReflection(_ quality: SleepQuality?, at date: Date) {
        if let quality {
            // Delegate to existing path — handles merging and insight trigger
            self.saveSleepQuality(quality, at: date)
        } else {
            // Clearing: write a reflection that removes sleep quality but keeps feeling
            let existing = self.historicalService.getSnapshot(for: date)?.reflection
            let cleared = DailyReflection(
                feeling: existing?.feeling,
                sleepQuality: nil,
                sleepLoggedAt: nil,
                feelingLoggedAt: existing?.feelingLoggedAt,
                note: existing?.note,
                timestamp: date
            )
            self.historicalService.updateReflection(for: date, reflection: cleared)
        }
    }

    // MARK: - HealthKit

    /// Fetches Apple sleep data for display in Highlight.
    private func fetchAppleSleepDataForHighlight() {
        Task {
            do {
                _ = try await HealthKitService.shared.requestAuthorization()
                if let sleepData = try await HealthKitService.shared.fetchSleepData(for: Date()) {
                    await MainActor.run {
                        self.appleSleepData = sleepData
                        self.suggestedSleepQuality = sleepData.sleepQuality
                    }
                }
            } catch {
                // Silently fail — user can still manually select sleep quality
            }
        }
    }
}
