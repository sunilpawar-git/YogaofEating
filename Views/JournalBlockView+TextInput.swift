import SwiftUI

extension JournalBlockView {
    var textInputSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                self.mealTextField
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Done button visibility is configurable via doneButtonVisibility
                if self.shouldShowDoneButton {
                    self.doneButton
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            self.itemCountFooter
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.2), value: self.isFocused)
    }

    /// Determines if Done button should be shown based on configuration
    var shouldShowDoneButton: Bool {
        switch Self.doneButtonVisibility {
        case .whenFocused:
            self.isFocused
        case .whenHasContent:
            self.isFocused && !self.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .never:
            false
        }
    }

    /// Done button to explicitly confirm entry and trigger AI analysis
    var doneButton: some View {
        Button {
            self.handleDoneButtonTap()
        } label: {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("done-button-\(self.meal.id)")
        .accessibilityLabel("Done")
        .accessibilityHint("Confirm meal entry and analyze")
    }

    func handleDoneButtonTap() {
        // Set flag to prevent handleFocusChange from also triggering AI
        self.skipNextFocusLoss = true
        // Dismiss keyboard (this will trigger handleFocusChange, but we skip it)
        self.isFocused = false
        // Trigger submit (which calls onUpdate for AI analysis)
        self.handleSubmit()
        // Haptic feedback
        SensoryService.shared.playNudge(style: .light)
    }

    var mealTextField: some View {
        TextField("What are you eating?", text: self.limitedTextBinding, axis: .vertical)
            .font(.system(size: 17, weight: .regular, design: .serif))
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
                // Sync rawText with external meal.items updates
                // Only sync if:
                // 1. NOT focused (user not actively typing)
                // 2. The new items are different from what we last sent
                //    (prevents AI analysis updates from resetting our text)
                if !self.isFocused, newItems != self.lastSentItems {
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
                // Enforce character limit silently (prevent abuse)
                if newValue.count > self.maxCharacterLimit {
                    self.rawText = String(newValue.prefix(self.maxCharacterLimit))
                } else {
                    self.rawText = newValue
                }
            }
        )
    }

    @ViewBuilder var itemCountFooter: some View {
        HStack {
            if !self.recentMeals.isEmpty {
                self.recentMealsButton
            }

            if !self.parsedItems.isEmpty {
                Text("\(self.parsedItems.count) item\(self.parsedItems.count == 1 ? "" : "s")")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            Spacer()
            self.timestampButton
        }
        .padding(.top, 4)
    }

    /// Small "+" button to show recent meals sheet
    var recentMealsButton: some View {
        RecentMealsAddButton(action: { self.showRecentMealsSheet = true })
            .accessibilityIdentifier("recent-meals-button-\(self.meal.id)")
            .accessibilityLabel("Add from recent meals")
            .accessibilityHint("Shows meals from the past 3 days")
            .sheet(isPresented: self.$showRecentMealsSheet) {
                RecentMealsSheetView(
                    recentMeals: self.recentMeals,
                    onSelectMeal: { meal in self.handleRecentMealSelection(meal) },
                    onDismiss: { self.showRecentMealsSheet = false }
                )
            }
    }

    /// Handles selection of a recent meal, merging with existing items
    func handleRecentMealSelection(_ meal: Meal) {
        let existingItems = self.parsedItems

        let mergedItems = MealItemsMerger.merge(existing: existingItems, new: meal.items)

        if existingItems.isEmpty {
            self.selectedMealType = meal.mealType
        }

        self.rawText = mergedItems.joined(separator: "\n")
        self.lastSentItems = mergedItems
        self.onUpdate(self.selectedMealType, mergedItems)
        self.showRecentMealsSheet = false
        SensoryService.shared.playNudge(style: .medium)
    }

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
