import SwiftUI

struct JournalBlockView: View {
    let meal: Meal
    let isBreathing: Bool
    let onUpdate: (MealType, [String]) -> Void
    let onDelete: () -> Void

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
        HStack {
            Spacer()
            // Centered block
            VStack(alignment: .leading, spacing: 12) {
                if self.isBreathing {
                    Text("Breathe...")
                        .font(.system(.subheadline, design: .serif))
                        .italic()
                        .foregroundColor(.secondary)
                } else {
                    // Minimalist Header: Tag with Menu
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

                    // Compact Divider (Invisible but adds spacing logic)
                    // We remove the explicit Divider view for minimalism

                    VStack(alignment: .leading, spacing: 4) {
                        // Multi-line text field for items - Serif, slightly larger
                        TextField("What are you eating?", text: self.$rawText, axis: .vertical)
                            .font(.system(size: 17, weight: .regular, design: .serif))
                            .foregroundColor(.primary)
                            .tint(.blue)
                            .textFieldStyle(.plain)
                            .lineLimit(1...10) // Allow 1-10 lines
                            .focused(self.$isFocused)
                            .accessibilityIdentifier("meal-text-field-\(self.meal.id)")
                            .onChange(of: self.rawText) { _, newValue in
                                // Cancel previous debounce task
                                self.debounceTask?.cancel()

                                // Debounce text input - only process after user stops typing
                                self.debounceTask = Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second debounce

                                    guard !Task.isCancelled else { return }

                                    let items = self.parseItems(from: newValue)
                                    self.onUpdate(self.selectedMealType, items)
                                }
                            }
                            .onChange(of: self.isFocused) { _, focused in
                                // When user finishes editing (focus lost), save immediately
                                if !focused {
                                    self.debounceTask?.cancel()
                                    let items = self.parseItems(from: self.rawText)
                                    self.onUpdate(self.selectedMealType, items)
                                }
                            }
                            .onSubmit {
                                // Immediate update when user presses return/done
                                self.debounceTask?.cancel()
                                let items = self.parseItems(from: self.rawText)
                                self.onUpdate(self.selectedMealType, items)
                            }

                        // Footer: Item counter only
                        HStack {
                            if !self.parsedItems.isEmpty {
                                Text("\(self.parsedItems.count) item\(self.parsedItems.count == 1 ? "" : "s")")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.8))
                            }

                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: 350) // Reasonable max width for readability
            .accessibilityIdentifier("meal-block-\(self.meal.id)")
            .background {
                RoundedRectangle(cornerRadius: 20) // Slightly tighter corners
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.4)) // Glassy look
                    }
                    .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(self.mealTypeColor.opacity(0.2), lineWidth: 1)
                    )
            }
            .scaleEffect(self.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: self.isPressed)
            .onLongPressGesture(minimumDuration: 0.5) {
                // Haptic feedback
                SensoryService.shared.playNudge(style: .heavy)
                self.showDeleteAlert = true
            } onPressingChanged: { pressing in
                self.isPressed = pressing
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    self.onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .alert("Delete this meal?", isPresented: self.$showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    self.onDelete()
                }
            } message: {
                Text("This action cannot be undone.")
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .onAppear {
            // Initialize state only once when view first appears
            if !self.hasInitialized {
                self.rawText = self.meal.items.joined(separator: "\n")
                self.selectedMealType = self.meal.mealType
                self.hasInitialized = true
            }
        }
    }

    // Parse items from raw text
    private func parseItems(from text: String) -> [String] {
        text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // Computed property for displaying parsed items
    private var parsedItems: [String] {
        self.parseItems(from: self.rawText)
    }

    // Color tint based on meal type
    private var mealTypeColor: Color {
        switch self.selectedMealType {
        case .breakfast:
            .orange
        case .lunch:
            .green
        case .dinner:
            .purple
        case .snacks:
            .pink
        case .drinks:
            .blue
        }
    }

    private func iconName(for type: MealType) -> String {
        switch type {
        case .breakfast:
            "sunrise.fill"
        case .lunch:
            "fork.knife"
        case .dinner:
            "moon.stars.fill"
        case .snacks:
            "popcorn.fill"
        case .drinks:
            "cup.and.saucer.fill"
        }
    }
}
