import SwiftUI

struct JournalBlockView: View {
    let meal: Meal
    let isBreathing: Bool
    let onUpdate: (MealType, [String]) -> Void
    let onDelete: () -> Void

    // Maximum character limit per callout box (silent limit, not shown to user)
    private let maxCharacterLimit: Int = 1000

    // Use meal.id as the key to persist state across view updates
    @State private var rawText: String = ""
    @State private var selectedMealType: MealType = .lunch
    @State private var isPressed: Bool = false
    @State private var showDeleteAlert: Bool = false
    @FocusState private var isFocused: Bool
    @State private var debounceTask: Task<Void, Never>?
    @State private var hasInitialized: Bool = false

    init(
        meal: Meal,
        isBreathing: Bool,
        onUpdate: @escaping (MealType, [String]) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.meal = meal
        self.isBreathing = isBreathing
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }

    var body: some View {
        self.cardContent
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            // Use explicit minimum dimensions with reasonable maxWidth to prevent overflow
            // Max width accounts for padding (40pt total) and leaves margin on most devices
            .frame(minWidth: 200, idealWidth: 300, maxWidth: 380, minHeight: 80, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("meal-block-\(self.meal.id)")
            .background { self.cardBackground }
            .scaleEffect(self.safeScaleEffect)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: self.isPressed)
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
                self.mealTypeMenu
                self.textInputSection
            }
        }
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
        if !self.parsedItems.isEmpty {
            Text("\(self.parsedItems.count) item\(self.parsedItems.count == 1 ? "" : "s")")
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.secondary.opacity(0.8))
                .padding(.top, 4)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.4))
            }
            .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(self.mealTypeColor.opacity(0.2), lineWidth: 1)
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
