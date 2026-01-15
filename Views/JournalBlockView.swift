import SwiftUI

struct JournalBlockView: View {
    let meal: Meal
    let isBreathing: Bool
    let onUpdate: (MealType, [String]) -> Void
    let onTimestampUpdate: (Date) -> Void
    let onDelete: () -> Void

    /// Recent meals from past 3 days for quick-add feature
    var recentMeals: [Meal] = []

    private let maxCharacterLimit: Int = 1000

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    @State private var rawText: String = ""
    @State private var selectedMealType: MealType = .lunch
    @State private var isPressed: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showTimePicker: Bool = false
    @State private var showRecentMealsSheet: Bool = false
    @State private var editedTimestamp: Date = .init()
    @FocusState private var isFocused: Bool
    @State private var debounceTask: Task<Void, Never>?
    @State private var hasInitialized: Bool = false
    /// Track the last items we sent to prevent external sync from overwriting during typing
    @State private var lastSentItems: [String] = []
    /// Controls visibility of score breakdown sheet
    @State private var showScoreBreakdown: Bool = false

    init(
        meal: Meal,
        isBreathing: Bool,
        onUpdate: @escaping (MealType, [String]) -> Void,
        onTimestampUpdate: @escaping (Date) -> Void = { _ in },
        onDelete: @escaping () -> Void,
        recentMeals: [Meal] = []
    ) {
        self.meal = meal
        self.isBreathing = isBreathing
        self.onUpdate = onUpdate
        self.onTimestampUpdate = onTimestampUpdate
        self.onDelete = onDelete
        self.recentMeals = recentMeals
    }

    var body: some View {
        self.cardContent
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minWidth: 200, idealWidth: 300, maxWidth: 340, minHeight: 70, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("meal-block-\(self.meal.id)")
            .background { MealCardBackground(feedback: self.feedback) }
            .scaleEffect(self.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: self.isPressed)
            .animation(.easeInOut(duration: 0.5), value: self.meal.healthScore)
            .onLongPressGesture(minimumDuration: 1.0) {
                SensoryService.shared.playNudge(style: .heavy)
                self.showDeleteAlert = true
            } onPressingChanged: { pressing in
                self.isPressed = pressing
            }
            .alert("Delete this meal?", isPresented: self.$showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { self.onDelete() }
            } message: {
                Text("This action cannot be undone.")
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .transition(.opacity)
            .onAppear { self.initializeState() }
            .sheet(isPresented: self.$showScoreBreakdown) {
                ScoreBreakdownSheet(meal: self.meal) {
                    self.showScoreBreakdown = false
                }
            }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if self.isBreathing {
                BreathingContentView()
            } else {
                self.cardHeader
                self.textInputSection
            }
        }
    }

    /// Header row with meal type tag (left) and score badge (right)
    private var cardHeader: some View {
        HStack {
            self.mealTypeMenu
            Spacer()
            MealScoreBadge(score: self.meal.healthScore) {
                self.showScoreBreakdown = true
            }
        }
    }

    private var mealTypeMenu: some View {
        Menu {
            ForEach(MealType.allCases, id: \.self) { type in
                Button {
                    self.selectedMealType = type
                    let items = self.parsedItems
                    self.lastSentItems = items
                    self.onUpdate(type, items)
                    SensoryService.shared.playNudge(style: .light)
                } label: {
                    Label(type.displayName, systemImage: type.iconName)
                }
            }
        } label: {
            MealTypeTag(mealType: self.selectedMealType, isSelected: true)
        }
        .animation(nil, value: self.selectedMealType)
    }

    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            self.mealTextField
            self.itemCountFooter
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mealTextField: some View {
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
    private var limitedTextBinding: Binding<String> {
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

    @ViewBuilder
    private var itemCountFooter: some View {
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
    private var recentMealsButton: some View {
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
    private func handleRecentMealSelection(_ meal: Meal) {
        let existingItems = self.parsedItems

        let mergedItems = MealItemsMerger.merge(existing: existingItems, new: meal.items)

        // Only update meal type if callout box was empty
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
    private var timestampButton: some View {
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

    // MARK: - Actions

    private func initializeState() {
        if !self.hasInitialized {
            self.rawText = self.meal.items.joined(separator: "\n")
            self.selectedMealType = self.meal.mealType
            self.lastSentItems = self.meal.items
            self.hasInitialized = true
        }
    }

    private func handleTextChange(_ newValue: String) {
        self.debounceTask?.cancel()
        self.debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            let items = self.parseItems(from: newValue)
            self.lastSentItems = items
            self.onUpdate(self.selectedMealType, items)
        }
    }

    private func handleFocusChange(_ focused: Bool) {
        if !focused {
            self.debounceTask?.cancel()
            let items = self.parseItems(from: self.rawText)
            self.lastSentItems = items
            self.onUpdate(self.selectedMealType, items)
        }
    }

    private func handleSubmit() {
        self.debounceTask?.cancel()
        let items = self.parseItems(from: self.rawText)
        self.lastSentItems = items
        self.onUpdate(self.selectedMealType, items)
    }

    // MARK: - Helpers

    private func parseItems(from text: String) -> [String] {
        text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var parsedItems: [String] {
        self.parseItems(from: self.rawText)
    }

    /// Visual feedback helper based on meal's health score
    private var feedback: MealCardFeedback {
        MealCardFeedback(score: self.meal.healthScore, mealTypeColor: self.selectedMealType.displayColor)
    }
}
