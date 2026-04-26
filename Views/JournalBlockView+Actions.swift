import SwiftUI

extension JournalBlockView {
    // MARK: - Actions

    func initializeState() {
        if !self.hasInitialized {
            self.rawText = self.meal.items.joined(separator: "\n")
            self.selectedMealType = self.meal.mealType
            self.lastSentItems = self.meal.items
            self.hasInitialized = true
        }
    }

    func handleTextChange(_ newValue: String) {
        self.debounceTask?.cancel()
        self.debounceTask = Task { @MainActor in
            // Short debounce for local updates - just enough to batch rapid keystrokes
            try? await Task.sleep(nanoseconds: Self.localUpdateDebounceNanoseconds)
            guard !Task.isCancelled else { return }
            let items = self.parseItems(from: newValue)
            self.lastSentItems = items
            // Use onLocalUpdate for typing - NO AI analysis triggered
            self.onLocalUpdate(self.selectedMealType, items)
        }
    }

    func handleFocusChange(_ focused: Bool) {
        if !focused {
            self.debounceTask?.cancel()

            // Skip if Done button already triggered the update
            if self.skipNextFocusLoss {
                self.skipNextFocusLoss = false
                return
            }

            let items = self.parseItems(from: self.rawText)
            self.lastSentItems = items
            // Use onUpdate for "done" action - triggers AI analysis
            self.onUpdate(self.selectedMealType, items)
        }
    }

    func handleSubmit() {
        self.debounceTask?.cancel()
        let items = self.parseItems(from: self.rawText)
        self.lastSentItems = items
        // Use onUpdate for "done" action - triggers AI analysis
        self.onUpdate(self.selectedMealType, items)
    }

    // MARK: - Helpers

    func parseItems(from text: String) -> [String] {
        text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var parsedItems: [String] {
        self.parseItems(from: self.rawText)
    }
}
