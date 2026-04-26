// swiftlint:disable file_length
import SwiftUI

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

    /// Pre-existing feeling from a previous save (restores selection when sheet re-opens).
    var existingFeeling: ReflectionFeeling?

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

    private var canSave: Bool { !self.showFeelingSelection || self.selectedFeeling != nil }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    self.morningTodosSection
                    Divider()
                    if self.showFeelingSelection {
                        self.feelingSection
                        Divider()
                    }
                    self.textInputSection(
                        emoji: MindCheckCategory.gratefulFor.emoji,
                        title: Strings.MindCheck.EveningReview.gratitudeHeader,
                        placeholder: "",
                        text: self.$gratitudeText,
                        field: .gratitude
                    )
                    Divider()
                    self.textInputSection(
                        emoji: MindCheckCategory.letGo.emoji,
                        title: Strings.MindCheck.EveningReview.letGoHeader,
                        placeholder: "",
                        text: self.$letGoText,
                        field: .letGo
                    )
                    Divider()
                    self.textInputSection(
                        emoji: MindCheckCategory.observation.emoji,
                        title: Strings.MindCheck.EveningReview.observationHeader,
                        placeholder: Strings.MindCheck.EveningReview.observationPlaceholder,
                        text: self.$observationText,
                        field: .observation
                    )
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
                        EveningReviewTodoCheckboxRow(
                            todo: todo,
                            isAccomplished: self.binding(for: todo.id)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Shared Text Input Section

    private func textInputSection(
        emoji: String,
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: Field
    ) -> some View {
        EveningReviewTextInputSection(
            emoji: emoji,
            title: title,
            placeholder: placeholder,
            text: text
        )
        .focused(self.$focusedField, equals: field)
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
                    EveningReviewFeelingButton(
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

        // Restore feeling selection when sheet re-opens
        if self.selectedFeeling == nil {
            self.selectedFeeling = self.existingFeeling
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
