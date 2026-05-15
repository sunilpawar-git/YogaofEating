import SwiftUI

// MARK: - JournalBlockView Input Section Extension

/// Text input, checkmark button, footer, and timestamp for JournalBlockView.
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

                // Always in layout (opacity-only toggle) so TextField width never changes.
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

    /// Green checkmark — the sole submission affordance.
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
    }

    /// Enforces the character limit silently (security boundary).
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
        self.rawText = mergedItems.joined(separator: "\n")
        self.showRecentMealsSheet = false
        self.handleSubmit()
        SensoryService.shared.playNudge(style: .medium)
    }

    // MARK: - Timestamp Button

    /// Neutral pill color — matches the visual family of MealScoreBadge without being score-dependent.
    private static let timePillColor = Color(red: 0.45, green: 0.5, blue: 0.55)

    var timestampButton: some View {
        Button {
            self.editedTimestamp = self.meal.timestamp
            self.showTimePicker = true
        } label: {
            HStack(spacing: 3) {
                Text(Self.timeFormatter.string(from: self.meal.timestamp))
                    .font(FontTheme.textEntry(size: 12, weight: .semibold))
                Image(systemName: "chevron.right")
                    .font(FontTheme.textEntry(size: 9, weight: .semibold))
            }
            .foregroundStyle(Color(.systemBackground))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Self.timePillColor)
            )
            .overlay(
                Capsule()
                    .strokeBorder(Self.timePillColor.opacity(0.7), lineWidth: 1.2)
            )
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
