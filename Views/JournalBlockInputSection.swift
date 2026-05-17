import SwiftUI

// MARK: - JournalBlockView Input Section Extension

/// Text input, checkmark button, footer, and timestamp for JournalBlockView.
/// Extracted to keep JournalBlockView under 300 lines.
extension JournalBlockView {
    // MARK: - Text Input Section

    var textInputSection: some View {
        let hasContent = self.draftItems.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let showCheckmark = self.isFocused && hasContent

        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                self.bulletItemsList
                    .frame(maxWidth: .infinity, alignment: .leading)

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

    // MARK: - Bullet Items List

    /// Per-item TextFields with bullet chrome. Bullets are UI-only — stored items are clean text.
    var bulletItemsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(self.draftItems.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .font(FontTheme.mealEntry)
                        .foregroundColor(self.bulletColor(for: i))

                    TextField(i == 0 ? Strings.Journal.placeholder : "", text: self.itemBinding(for: i))
                        .font(FontTheme.mealEntry)
                        .foregroundColor(.primary)
                        .tint(.blue)
                        .textFieldStyle(.plain)
                        .focused(self.$focusedItemIndex, equals: i)
                        .onSubmit { self.appendItem(after: i) }
                        .accessibilityIdentifier("meal-item-field-\(self.meal.id)-\(i)")
                }
            }
        }
    }

    private func bulletColor(for index: Int) -> Color {
        let isEmpty = index < self.draftItems.count && self.draftItems[index].isEmpty
        return isEmpty && index == 0 ? .secondary.opacity(0.35) : .primary
    }

    // MARK: - Item Management

    func appendItem(after index: Int) {
        let insertAt = min(index + 1, self.draftItems.count)
        self.draftItems.insert("", at: insertAt)
        Task { @MainActor in
            self.focusedItemIndex = insertAt
        }
    }

    /// Per-item binding that enforces the character limit.
    func itemBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard index < self.draftItems.count else { return "" }
                return self.draftItems[index]
            },
            set: { newValue in
                guard index < self.draftItems.count else { return }
                self.draftItems[index] = String(newValue.prefix(Self.maxCharacterLimit))
            }
        )
    }

    // MARK: - Checkmark Button

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
        .accessibilityLabel(Strings.Accessibility.submitMealEntry)
        .accessibilityHint(Strings.Accessibility.submitMealHint)
    }

    // MARK: - Footer

    @ViewBuilder
    var itemCountFooter: some View {
        HStack {
            if !self.isFocused {
                self.recentMealsButton
            }

            if !self.isFocused, !self.parsedItems.isEmpty {
                Text(Strings.Journal.itemCount(self.parsedItems.count))
                    .font(FontTheme.iconSmall)
                    .foregroundColor(.secondary.opacity(0.8))
            }
            Spacer()

            self.timestampButton
        }
        .padding(.top, 4)
    }

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
        if existingItems.isEmpty {
            self.selectedMealType = meal.mealType
        }
        self.draftItems = mergedItems.isEmpty ? [""] : mergedItems
        self.showRecentMealsSheet = false
        SensoryService.shared.playNudge(style: .medium)
    }

    // MARK: - Timestamp Button

    var timestampButton: some View {
        let pillColor = self.selectedMealType.displayColor
        return Button {
            self.editedTimestamp = self.meal.timestamp
            self.showTimePicker = true
        } label: {
            HStack(spacing: 3) {
                Text(Self.timeFormatter.string(from: self.meal.timestamp))
                    .font(FontTheme.textEntry(size: 12, weight: .semibold))
                Image(systemName: "chevron.right")
                    .font(FontTheme.textEntry(size: 9, weight: .semibold))
            }
            .foregroundStyle(pillColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .coloredCapsulePill(color: pillColor)
            .mealPillShadow()
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
