import SwiftUI

// MARK: - JournalBlockView Input Section Extension

/// Text input, done button, item count footer, and timestamp button for JournalBlockView.
/// Extracted to keep JournalBlockView under 300 lines.
extension JournalBlockView {
    // MARK: - Text Input Section

    var textInputSection: some View {
        let hasContent = !self.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let showCheckmark = self.isFocused && hasContent

        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                self.mealTextField
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Checkmark is always in the layout to keep TextField width stable.
                // Opacity-only show/hide avoids the layout recalculation that causes
                // the multiline TextField to briefly render blank when content appears.
                self.checkmarkButton
                    .opacity(showCheckmark ? 1 : 0)
                    .allowsHitTesting(showCheckmark)
                    .animation(.easeInOut(duration: 0.2), value: showCheckmark)
            }
            self.itemCountFooter
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.2), value: self.isFocused)
    }

    /// Green checkmark icon to submit meal entry (implicit affordance)
    /// Submission also occurs via Return key or focus loss
    var checkmarkButton: some View {
        Button {
            self.handleCheckmarkTap()
        } label: {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("checkmark-button-\(self.meal.id)")
        .accessibilityLabel("Submit meal entry")
        .accessibilityHint("Tap to save and analyze this meal")
    }

    func handleCheckmarkTap() {
        // Set flag to prevent handleFocusChange from also triggering AI
        self.skipNextFocusLoss = true
        // Dismiss keyboard (this will trigger handleFocusChange, but we skip it)
        self.isFocused = false
        // Trigger submit (which calls onUpdate for AI analysis)
        self.handleSubmit()
        SensoryService.shared.playNudge(style: .light)
    }

    // MARK: - Text Field

    var mealTextField: some View {
        TextField(Strings.Journal.placeholder, text: self.limitedTextBinding, axis: .vertical)
            .font(FontTheme.mealEntry)
            .foregroundColor(.primary)
            .tint(.blue)
            .textFieldStyle(.plain)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .focused(self.$isFocused)
            .accessibilityIdentifier("meal-text-field-\(self.meal.id)")
            .onChange(of: self.rawText) { _, newValue in
                self.handleTextChange(newValue)
            }
            .onChange(of: self.isFocused) { _, focused in
                self.handleFocusChange(focused)
            }
            .onChange(of: self.meal.items) { _, newItems in
                // Sync rawText with external meal.items updates (e.g. AI score write-back).
                // Guard on isUserEditing rather than isFocused: @FocusState can desync to
                // false during haptics, alerts, or scroll events while the keyboard is still
                // up. isUserEditing is set on every keystroke and cleared only on genuine
                // focus loss, so it reliably prevents overwriting live typing.
                if !self.isUserEditing, newItems != self.lastSentItems {
                    let externalText = newItems.joined(separator: "\n")
                    if self.rawText != externalText {
                        self.rawText = externalText
                        self.lastSentItems = newItems
                    }
                }
            }
            .onSubmit {
                self.handleSubmit()
            }
    }

    /// Custom binding that enforces the character limit silently
    var limitedTextBinding: Binding<String> {
        Binding(
            get: { self.rawText },
            set: { newValue in
                if newValue.count > Self.maxCharacterLimit {
                    self.rawText = String(newValue.prefix(Self.maxCharacterLimit))
                } else {
                    self.rawText = newValue
                }
            }
        )
    }

    // MARK: - Footer

    @ViewBuilder
    var itemCountFooter: some View {
        HStack {
            // Show recent meals button when has recents (always visible for quick access)
            if !self.recentMeals.isEmpty {
                self.recentMealsButton
            }

            // Item count (shown when not focused and has content)
            if !self.isFocused, !self.parsedItems.isEmpty {
                Text(Strings.Journal.itemCount(self.parsedItems.count))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            Spacer()

            // Timestamp always shown (critical for user awareness)
            self.timestampButton
        }
        .padding(.top, 4)
    }

    /// Small "+" button to show recent meals sheet.
    /// Accessibility label and hint are provided by `RecentMealsAddButton` via `Strings.Accessibility`.
    var recentMealsButton: some View {
        RecentMealsAddButton(action: { self.showRecentMealsSheet = true })
            .accessibilityIdentifier("recent-meals-button-\(self.meal.id)")
            .sheet(isPresented: self.$showRecentMealsSheet) {
                RecentMealsSheetView(
                    recentMeals: self.recentMeals,
                    onSelectMeal: { meal in self.handleRecentMealSelection(meal) },
                    onDismiss: { self.showRecentMealsSheet = false }
                )
            }
    }

    func handleRecentMealSelection(_ meal: Meal) {
        let existingItems = self.parsedItems
        let mergedItems = MealItemsMerger.merge(existing: existingItems, new: meal.items)
        // Only update meal type if the entry was empty
        if existingItems.isEmpty {
            self.selectedMealType = meal.mealType
        }
        self.rawText = mergedItems.joined(separator: "\n")
        self.lastSentItems = mergedItems
        self.onUpdate(self.selectedMealType, mergedItems)
        self.showRecentMealsSheet = false
        SensoryService.shared.playNudge(style: .medium)
    }

    // MARK: - Timestamp Button

    /// Minimalist time display in bottom-right, tap to edit
    var timestampButton: some View {
        Button {
            self.editedTimestamp = self.meal.timestamp
            self.showTimePicker = true
        } label: {
            Text(Self.timeFormatter.string(from: self.meal.timestamp))
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("meal-time-button-\(self.meal.id)")
        .accessibilityLabel("Meal time: \(Self.timeFormatter.string(from: self.meal.timestamp)). Tap to edit.")
        .sheet(isPresented: self.$showTimePicker) {
            TimePickerSheetView(
                selectedTime: self.$editedTimestamp,
                onSave: {
                    self.onTimestampUpdate(self.editedTimestamp)
                    self.showTimePicker = false
                },
                onCancel: {
                    self.showTimePicker = false
                }
            )
        }
    }
}
