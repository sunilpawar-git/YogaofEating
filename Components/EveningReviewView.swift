import SwiftUI

/// A sheet view for evening reflection that shows morning todos with checkboxes
/// and allows adding gratitude and let-go entries.
/// Phase 3: Now also supports feeling selection for holistic End-of-Day capture.
/// This creates an accountability loop - user reviews what they set out to do.
struct EveningReviewView: View {
    // MARK: - Properties

    /// Morning entries to review (todos will be shown with checkboxes)
    let morningEntries: [MindCheckEntry]

    /// Existing evening entries if editing
    let existingEveningEntries: [MindCheckEntry]?

    /// Whether to show feeling selection (true when called from End-of-Day pill)
    var showFeelingSelection: Bool = false

    /// Callback when user saves their review (with optional feeling for End-of-Day flow)
    let onSave: ([MindCheckEntry], [MindCheckEntry], ReflectionFeeling?) -> Void

    /// Callback when user dismisses without saving
    let onDismiss: () -> Void

    // MARK: - State

    /// Track accomplished status for each morning todo
    @State private var todoStatuses: [UUID: Bool] = [:]

    /// Gratitude text input
    @State private var gratitudeText: String = ""

    /// Let go text input
    @State private var letGoText: String = ""

    /// Observation text input
    @State private var observationText: String = ""

    /// Selected feeling (for End-of-Day flow)
    @State private var selectedFeeling: ReflectionFeeling?

    @FocusState private var focusedField: Field?

    private enum Field {
        case gratitude
        case letGo
        case observation
    }

    // MARK: - Computed

    private var morningTodos: [MindCheckEntry] {
        self.morningEntries.filter { $0.category == .todo }
    }

    /// For End-of-Day flow, feeling is required to save
    private var canSave: Bool {
        if self.showFeelingSelection {
            return self.selectedFeeling != nil
        }
        return true
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Morning todos section with checkboxes
                    self.morningTodosSection

                    Divider()

                    // Feeling section (Phase 3: for End-of-Day holistic capture)
                    if self.showFeelingSelection {
                        self.feelingSection

                        Divider()
                    }

                    // Gratitude section
                    self.gratitudeSection

                    Divider()

                    // Let go section
                    self.letGoSection

                    Divider()

                    // Observation section
                    self.observationSection
                }
                .padding()
            }
            .navigationTitle(Strings.MindCheck.eveningTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.MindCheck.cancelButton) {
                        self.onDismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.MindCheck.saveButton) {
                        self.saveReview()
                    }
                    .disabled(!self.canSave)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            self.initializeState()
        }
    }

    // MARK: - Morning Todos Section

    private var morningTodosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text(Strings.MindCheck.EveningReview.morningTodosHeader)
                .font(.headline)
                .foregroundColor(.primary)

            if self.morningTodos.isEmpty {
                Text(Strings.MindCheck.EveningReview.noMorningTodos)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(self.morningTodos) { todo in
                        TodoCheckboxRow(
                            todo: todo,
                            isAccomplished: self.binding(for: todo.id)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Gratitude Section

    private var gratitudeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Text(MindCheckCategory.gratefulFor.emoji)
                    .font(.title3)
                Text(Strings.MindCheck.EveningReview.gratitudeHeader)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            TextField("", text: self.$gratitudeText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .focused(self.$focusedField, equals: .gratitude)
                .lineLimit(3...5)
        }
    }

    // MARK: - Let Go Section

    private var letGoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Text(MindCheckCategory.letGo.emoji)
                    .font(.title3)
                Text(Strings.MindCheck.EveningReview.letGoHeader)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            TextField("", text: self.$letGoText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .focused(self.$focusedField, equals: .letGo)
                .lineLimit(3...5)
        }
    }

    // MARK: - Observation Section

    private var observationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(MindCheckCategory.observation.emoji)
                    .font(.title3)
                Text(Strings.MindCheck.EveningReview.observationHeader)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            TextField(
                Strings.MindCheck.EveningReview.observationPlaceholder,
                text: self.$observationText,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .focused(self.$focusedField, equals: .observation)
            .lineLimit(3...5)
        }
    }

    // MARK: - Feeling Section (Phase 3: End-of-Day)

    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text(Strings.MindCheck.EveningReview.feelingHeader)
                .font(.headline)
                .foregroundColor(.primary)

            // Feeling picker - horizontal row of emoji buttons
            HStack(spacing: 12) {
                ForEach(ReflectionFeeling.allCases, id: \.self) { feeling in
                    FeelingButton(
                        feeling: feeling,
                        isSelected: self.selectedFeeling == feeling
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.selectedFeeling = feeling
                        }
                        SensoryService.shared.playNudge(style: .light)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Helpers

    private func binding(for todoId: UUID) -> Binding<Bool> {
        Binding(
            get: { self.todoStatuses[todoId] ?? false },
            set: { self.todoStatuses[todoId] = $0 }
        )
    }

    private func initializeState() {
        // Initialize todo statuses from existing data
        for todo in self.morningTodos {
            self.todoStatuses[todo.id] = todo.isAccomplished ?? false
        }

        // Initialize text fields from existing evening entries
        if let existing = self.existingEveningEntries {
            if let gratitude = existing.first(where: { $0.category == .gratefulFor }) {
                self.gratitudeText = gratitude.text
            }
            if let letGo = existing.first(where: { $0.category == .letGo }) {
                self.letGoText = letGo.text
            }
            if let observation = existing.first(where: { $0.category == .observation }) {
                self.observationText = observation.text
            }
        }
    }

    private func saveReview() {
        // Update morning todos with accomplished status
        let updatedMorningEntries = self.morningEntries.map { entry in
            if entry.category == .todo {
                return entry.withAccomplished(self.todoStatuses[entry.id] ?? false)
            }
            return entry
        }

        // Create evening entries
        var eveningEntries: [MindCheckEntry] = []

        let trimmedGratitude = self.gratitudeText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedGratitude.isEmpty {
            eveningEntries.append(
                MindCheckEntry(
                    category: .gratefulFor,
                    text: trimmedGratitude,
                    context: .evening
                )
            )
        }

        let trimmedLetGo = self.letGoText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedLetGo.isEmpty {
            eveningEntries.append(
                MindCheckEntry(
                    category: .letGo,
                    text: trimmedLetGo,
                    context: .evening
                )
            )
        }

        let trimmedObservation = self.observationText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedObservation.isEmpty {
            eveningEntries.append(
                MindCheckEntry(
                    category: .observation,
                    text: trimmedObservation,
                    context: .evening
                )
            )
        }

        // Pass feeling for End-of-Day flow (Phase 3)
        self.onSave(updatedMorningEntries, eveningEntries, self.selectedFeeling)
    }
}

// MARK: - Feeling Button (Phase 3)

/// A button for selecting feeling in the evening review
private struct FeelingButton: View {
    let feeling: ReflectionFeeling
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            VStack(spacing: 4) {
                Text(self.feeling.emoji)
                    .font(.system(size: 28))

                Text(self.feeling.displayName)
                    .font(.caption2)
                    .foregroundColor(self.isSelected ? .primary : .secondary)
            }
            .frame(minWidth: 54)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(self.isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(self.isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(self.feeling.displayName), \(self.isSelected ? "selected" : "not selected")")
    }
}

// MARK: - Todo Checkbox Row

/// A row displaying a morning todo with a checkbox to mark as done/not done
struct TodoCheckboxRow: View {
    let todo: MindCheckEntry
    @Binding var isAccomplished: Bool

    var body: some View {
        Button {
            self.isAccomplished.toggle()
            SensoryService.shared.playNudge(style: .light)
        } label: {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: self.isAccomplished ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(self.isAccomplished ? .green : .secondary.opacity(0.5))

                // Todo text
                Text(self.todo.text)
                    .font(.body)
                    .foregroundColor(self.isAccomplished ? .secondary : .primary)
                    .strikethrough(self.isAccomplished, color: .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Status label
                Text(self.isAccomplished ? Strings.MindCheck.EveningReview.accomplished : Strings.MindCheck
                    .EveningReview.notAccomplished)
                    .font(.caption)
                    .foregroundColor(self.isAccomplished ? .green : .secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(self.isAccomplished ? Color.green.opacity(0.08) : Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(self.isAccomplished ? Color.green.opacity(0.2) : Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(self.todo.text), \(self.isAccomplished ? "completed" : "not completed")")
        .accessibilityHint("Tap to toggle completion status")
    }
}

// MARK: - Preview

#if DEBUG
    #Preview("With Morning Todos") {
        EveningReviewView(
            morningEntries: [
                MindCheckEntry(category: .todo, text: "Buy groceries", context: .morning),
                MindCheckEntry(category: .todo, text: "Call mom", context: .morning),
                MindCheckEntry(category: .gratitude, text: "Good health", context: .morning)
            ],
            existingEveningEntries: nil,
            onSave: { _, _, _ in print("Saved") },
            onDismiss: { print("Dismissed") }
        )
    }

    #Preview("End of Day Flow (with Feeling)") {
        EveningReviewView(
            morningEntries: [
                MindCheckEntry(category: .todo, text: "Exercise", context: .morning),
                MindCheckEntry(category: .todo, text: "Read book", context: .morning)
            ],
            existingEveningEntries: nil,
            showFeelingSelection: true,
            onSave: { _, _, feeling in print("Saved with feeling: \(String(describing: feeling))") },
            onDismiss: { print("Dismissed") }
        )
    }

    #Preview("No Morning Todos") {
        EveningReviewView(
            morningEntries: [
                MindCheckEntry(category: .gratitude, text: "Good health", context: .morning)
            ],
            existingEveningEntries: nil,
            onSave: { _, _, _ in print("Saved") },
            onDismiss: { print("Dismissed") }
        )
    }
#endif
