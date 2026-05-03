import SwiftUI

// MARK: - To-Do Review Section

struct ReflectTodoReviewSection: View {
    let todos: [MindCheckEntry]
    var onToggle: ((UUID) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Morning Review", systemImage: "checklist.checked")
                .font(.headline)
                .padding(.horizontal)

            if self.todos.isEmpty {
                Text("No morning to-dos to review")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            } else {
                ForEach(self.todos) { todo in
                    self.todoCheckbox(todo)
                }
            }
        }
    }

    private func todoCheckbox(_ todo: MindCheckEntry) -> some View {
        let isDone = todo.isAccomplished ?? false

        return Button {
            self.onToggle?(todo.id)
            SensoryService.shared.playNudge(style: .light)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isDone ? .green : .secondary.opacity(0.4))

                Text(todo.text)
                    .font(.body)
                    .foregroundColor(isDone ? .secondary : .primary)
                    .strikethrough(isDone, color: .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDone ? Color.green.opacity(0.06) : Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isDone ? Color.green.opacity(0.15) : Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .accessibilityLabel("\(todo.text), \(isDone ? "completed" : "not completed")")
    }
}

// MARK: - Journal Section

struct ReflectJournalSection: View {
    @Binding var text: String
    /// Bound to the parent's @FocusState so the parent can detect active edits
    /// and skip mid-keystroke data resets when navigating dates.
    var isJournalFocused: FocusState<Bool>.Binding
    var onChanged: ((String) -> Void)?

    @State private var journalDebounce: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Evening Journal", systemImage: "book.closed")
                .font(.headline)
                .padding(.horizontal)

            TextEditor(text: self.$text)
                .font(FontTheme.textEntry)
                .frame(minHeight: 150)
                .scrollContentBackground(.hidden)
                .focused(self.isJournalFocused)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if self.text.isEmpty {
                        Text("What went well today? What would you let go of?")
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal)
                .onChange(of: self.text) { _, newValue in
                    // Enforce max length based on InputValidator constraints
                    if newValue.count > InputValidator.journalEntryMaxLength {
                        self.text = String(newValue.prefix(InputValidator.journalEntryMaxLength))
                        return
                    }
                    self.journalDebounce?.cancel()
                    self.journalDebounce = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: AppTheme.TextEntry.debounceNanoseconds)
                        guard !Task.isCancelled else { return }
                        self.onChanged?(newValue)
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            self.isJournalFocused.wrappedValue = false
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
    }
}

// MARK: - Feeling Section

struct ReflectFeelingSection: View {
    let selectedFeeling: ReflectionFeeling?
    var onChanged: ((ReflectionFeeling?) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How do you feel?", systemImage: "face.smiling")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 12) {
                ForEach(ReflectionFeeling.allCases, id: \.self) { feeling in
                    self.feelingButton(feeling)
                }
            }
            .padding(.horizontal)
        }
    }

    private func feelingButton(_ feeling: ReflectionFeeling) -> some View {
        let isSelected = self.selectedFeeling == feeling

        return Button {
            self.onChanged?(isSelected ? nil : feeling)
            SensoryService.shared.playNudge(style: .light)
        } label: {
            VStack(spacing: 4) {
                Text(feeling.emoji)
                    .font(.system(size: 28))
                Text(feeling.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("reflect-feeling-\(feeling.rawValue)")
    }
}
