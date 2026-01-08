import SwiftUI

struct JournalBlockView: View {
    let meal: Meal
    let isBreathing: Bool
    let onUpdate: (MealType, [String]) -> Void
    let onTimestampUpdate: (Date) -> Void
    let onDelete: () -> Void

    /// Recent meals from past 3 days for quick-add feature
    var recentMeals: [Meal] = []

    // Maximum character limit per callout box (silent limit, not shown to user)
    private let maxCharacterLimit: Int = 1000

    // Shared time formatter to avoid repeated allocations
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    // Use meal.id as the key to persist state across view updates
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
            // Use explicit minimum dimensions with reasonable maxWidth to prevent overflow
            // Max width accounts for padding and leaves margin on most devices
            .frame(minWidth: 200, idealWidth: 300, maxWidth: 340, minHeight: 70, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("meal-block-\(self.meal.id)")
            .background { self.cardBackground }
            .scaleEffect(self.safeScaleEffect)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: self.isPressed)
            .animation(.easeInOut(duration: 0.5), value: self.meal.healthScore)
            .onLongPressGesture(minimumDuration: 0.5) {
                SensoryService.shared.playNudge(style: .heavy)
                self.showDeleteAlert = true
            } onPressingChanged: { pressing in
                self.isPressed = pressing
            }
            .modifier(DeleteActionModifier(onDelete: self.onDelete))
            .alert("Delete this meal?", isPresented: self.$showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { self.onDelete() }
            } message: {
                Text("This action cannot be undone.")
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .transition(.opacity)
            .onAppear { self.initializeState() }
    }

    /// Safe scale effect that's always valid
    private var safeScaleEffect: CGFloat {
        let scale: CGFloat = self.isPressed ? 0.96 : 1.0
        // Ensure the scale is always finite and positive
        return scale.isFinite && scale > 0 ? scale : 1.0
    }

    // MARK: - Subviews

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if self.isBreathing {
                self.breathingContent
            } else {
                self.cardHeader
                self.textInputSection
            }
        }
    }

    /// Header row with meal type tag (left) and AI sparkle indicator (right)
    private var cardHeader: some View {
        HStack {
            self.mealTypeMenu
            Spacer()
            if self.meal.isAIAnalyzed {
                self.aiSparkleIndicator
            }
        }
    }

    /// Sparkle indicator shown after AI analysis completes
    private var aiSparkleIndicator: some View {
        Text("✨")
            .font(.system(size: 14))
            .transition(.opacity.combined(with: .scale))
            .animation(.easeIn(duration: 0.3), value: self.meal.isAIAnalyzed)
            .accessibilityLabel("AI analyzed")
            .accessibilityHint("This meal has been analyzed by AI")
    }

    private var breathingContent: some View {
        Text("Breathe...")
            .font(.system(.subheadline, design: .serif))
            .italic()
            .foregroundColor(.secondary)
    }

    private var mealTypeMenu: some View {
        Menu {
            ForEach(MealType.allCases, id: \.self) { type in
                Button {
                    self.selectedMealType = type
                    self.onUpdate(type, self.parsedItems)
                    SensoryService.shared.playNudge(style: .light)
                } label: {
                    Label(type.displayName, systemImage: self.iconName(for: type))
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
                // Only sync when NOT focused to avoid overwriting user's active typing
                if !self.isFocused {
                    let externalText = newItems.joined(separator: "\n")
                    if self.rawText != externalText {
                        self.rawText = externalText
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
            // "+" button for recent meals (only show if recent meals available)
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
        Button {
            SensoryService.shared.playNudge(style: .light)
            self.showRecentMealsSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.7))
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("recent-meals-button-\(self.meal.id)")
        .accessibilityLabel("Add from recent meals")
        .accessibilityHint("Shows meals from the past 3 days")
        .sheet(isPresented: self.$showRecentMealsSheet) {
            self.recentMealsSheet
        }
    }

    /// Sheet displaying recent meals for quick selection
    private var recentMealsSheet: some View {
        NavigationStack {
            List {
                if self.recentMeals.isEmpty {
                    Text("No recent meals")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(self.recentMeals) { recentMeal in
                        Button {
                            self.selectRecentMeal(recentMeal)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recentMeal.items.joined(separator: ", "))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)

                                HStack {
                                    Text(recentMeal.mealType.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Text(Self.relativeDateString(from: recentMeal.timestamp))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Recent Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        self.showRecentMealsSheet = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    /// Selects a recent meal and appends to existing items (or sets if empty)
    private func selectRecentMeal(_ meal: Meal) {
        let existingItems = self.parsedItems

        // Use MealItemsMerger for consistent merge logic
        let mergedItems = MealItemsMerger.merge(existing: existingItems, new: meal.items)

        // Only update meal type if callout box was empty
        if existingItems.isEmpty {
            self.selectedMealType = meal.mealType
        }

        self.rawText = mergedItems.joined(separator: "\n")
        self.onUpdate(self.selectedMealType, mergedItems)
        self.showRecentMealsSheet = false
        SensoryService.shared.playNudge(style: .medium)
    }

    /// Returns a relative date string like "Yesterday" or "2 days ago"
    private static func relativeDateString(from date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let mealDay = calendar.startOfDay(for: date)

        let daysDiff = calendar.dateComponents([.day], from: mealDay, to: today).day ?? 0

        switch daysDiff {
        case 0: return "Today"
        case 1: return "Yesterday"
        default: return "\(daysDiff) days ago"
        }
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
            self.timePickerSheet
        }
    }

    /// iOS-style time picker sheet
    private var timePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "Meal Time",
                    selection: self.$editedTimestamp,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Edit Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        self.showTimePicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        self.onTimestampUpdate(self.editedTimestamp)
                        self.showTimePicker = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.4))
            }
            .overlay {
                // Subtle tint overlay for visual feedback
                RoundedRectangle(cornerRadius: 16)
                    .fill(self.feedback.tintColor.opacity(self.feedback.tintOpacity))
            }
            .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(self.feedback.borderColor, lineWidth: self.feedback.borderWidth)
            )
    }

    // MARK: - Actions

    private func initializeState() {
        if !self.hasInitialized {
            self.rawText = self.meal.items.joined(separator: "\n")
            self.selectedMealType = self.meal.mealType
            self.hasInitialized = true
        }
    }

    private func handleTextChange(_ newValue: String) {
        self.debounceTask?.cancel()
        self.debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            let items = self.parseItems(from: newValue)
            self.onUpdate(self.selectedMealType, items)
        }
    }

    private func handleFocusChange(_ focused: Bool) {
        if !focused {
            self.debounceTask?.cancel()
            let items = self.parseItems(from: self.rawText)
            self.onUpdate(self.selectedMealType, items)
        }
    }

    private func handleSubmit() {
        self.debounceTask?.cancel()
        let items = self.parseItems(from: self.rawText)
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

    private var mealTypeColor: Color {
        switch self.selectedMealType {
        case .breakfast: .orange
        case .lunch: .green
        case .dinner: .purple
        case .snacks: .pink
        case .drinks: .blue
        }
    }

    /// Visual feedback helper based on meal's health score
    private var feedback: MealCardFeedback {
        MealCardFeedback(score: self.meal.healthScore, mealTypeColor: self.mealTypeColor)
    }

    private func iconName(for type: MealType) -> String {
        switch type {
        case .breakfast: "sunrise.fill"
        case .lunch: "fork.knife"
        case .dinner: "moon.stars.fill"
        case .snacks: "popcorn.fill"
        case .drinks: "cup.and.saucer.fill"
        }
    }
}

// MARK: - Delete Action Modifier

private struct DeleteActionModifier: ViewModifier {
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content.swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                self.onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
