import Foundation

// MARK: - Reflect Tab Extension

extension MainViewModel {
    // MARK: - Read Helpers

    /// Returns today's ReflectData, creating a default if none exists.
    private func currentOrNewReflectData() -> ReflectData {
        self.currentReflectData ?? ReflectData()
    }

    // MARK: - Update Methods (Auto-Save)

    /// Updates the journal text in Reflect and persists.
    func updateReflectJournalText(_ text: String) {
        guard self.isViewingToday else { return }
        let trimmed = Self.clampText(text).trimmingCharacters(in: .whitespacesAndNewlines)

        // Allow empty for optional field
        if trimmed.isEmpty {
            var data = self.currentOrNewReflectData()
            data.journalText = nil
            data.lastModified = Date()
            self.historicalService.updateReflectData(for: self.selectedDate, data: data)
            return
        }

        // Validate non-empty journal text — extractor runs AFTER validation (security boundary)
        switch InputValidator.validateJournalEntry(trimmed) {
        case let .success(sanitized):
            var data = self.currentOrNewReflectData()
            data.journalText = sanitized
            data.textSignals = self.textSignalExtractor.extractSignals(from: sanitized, context: .eveningJournal)
            data.lastModified = Date()
            self.historicalService.updateReflectData(for: self.selectedDate, data: data)
            self.synthesisScheduler.schedule(.journalSaved)
        case let .failure(error):
            self.lastValidationError = error
            self.showValidationErrorAlert = true
        }
    }

    /// Updates the feeling emoji in Reflect and persists.
    func updateReflectFeeling(_ feeling: ReflectionFeeling?) {
        guard self.isViewingToday else { return }
        var data = self.currentOrNewReflectData()
        data.feeling = feeling
        data.lastModified = Date()
        self.historicalService.updateReflectData(for: self.selectedDate, data: data)

        // Mirror to legacy reflection so the insight pipeline stays in sync.
        // Always write (even nil) so both stores agree when user clears their feeling.
        self.syncFeelingToLegacyReflection(feeling, at: self.selectedDate)
        self.synthesisScheduler.schedule(.feelingUpdated)
    }

    /// Toggles accomplished status for a morning to-do item.
    /// Updates the to-do in HighlightData since that's the source of truth.
    func toggleTodoAccomplished(_ todoId: UUID) {
        guard self.isViewingToday else { return }
        guard var highlightData = self.currentHighlightData else { return }
        guard let index = highlightData.todos.firstIndex(where: { $0.id == todoId }) else { return }

        let current = highlightData.todos[index].isAccomplished ?? false
        highlightData.todos[index] = highlightData.todos[index].withAccomplished(!current)
        highlightData.lastModified = Date()
        self.historicalService.updateHighlightData(for: self.selectedDate, data: highlightData)
        self.synthesisScheduler.schedule(.todoCompleted)
    }

    // MARK: - Private Helpers

    /// Syncs the feeling (or its absence) to the legacy DailyReflection store
    /// so the insight pipeline stays consistent with ReflectData.
    private func syncFeelingToLegacyReflection(_ feeling: ReflectionFeeling?, at date: Date) {
        let existing = self.historicalService.getSnapshot(for: date)?.reflection
        let updated = DailyReflection(
            feeling: feeling,
            sleepQuality: existing?.sleepQuality,
            sleepLoggedAt: existing?.sleepLoggedAt,
            feelingLoggedAt: feeling != nil ? date : nil,
            note: existing?.note,
            timestamp: date
        )
        self.historicalService.updateReflection(for: date, reflection: updated)
    }
}
