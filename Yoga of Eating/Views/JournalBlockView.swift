import SwiftUI

struct JournalBlockView: View {
    let meal: Meal
    let isBreathing: Bool
    let onUpdate: (MealType, [String]) -> Void
    let onDelete: () -> Void

    @State private var rawText: String
    @State private var selectedMealType: MealType
    @State private var isPressed: Bool = false
    @State private var showDeleteAlert: Bool = false
    @FocusState private var isFocused: Bool

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
        _rawText = State(initialValue: meal.items.joined(separator: "\n"))
        _selectedMealType = State(initialValue: meal.mealType)
    }

    var body: some View {
        HStack {
            // Left-aligned block
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
                        // Multi-line text editor for items - Serif, slightly larger
                        TextEditor(text: self.$rawText)
                            .font(.system(size: 17, weight: .regular, design: .serif))
                            .frame(minHeight: 44) // Smaller minimum height
                            .scrollContentBackground(.hidden)
                            .focused(self.$isFocused)
                            .onChange(of: self.rawText) { _, newValue in
                                let items = self.parseItems(from: newValue)
                                self.onUpdate(self.selectedMealType, items)
                            }
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        self.isFocused = false
                                    }
                                    .fontWeight(.semibold)
                                }
                            }

                        // Footer: Item counter and Done button
                        HStack {
                            if !self.parsedItems.isEmpty {
                                Text("\(self.parsedItems.count) item\(self.parsedItems.count == 1 ? "" : "s")")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.8))
                            }

                            Spacer()

                            if self.isFocused {
                                Button {
                                    self.isFocused = false
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("Done")
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.top, 4)
                        .animation(.spring(response: 0.3), value: self.isFocused)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: 300, alignment: .leading) // More compact width
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
        .padding(.leading, 32) // Position relative to vertical line
        .transition(.move(edge: .trailing).combined(with: .opacity))
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
