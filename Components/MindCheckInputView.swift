import SwiftUI

/// A sheet view for entering mind check entries.
/// Allows user to add entries with category tag + text for each.
/// Supports both creating new entries and editing existing ones.
struct MindCheckInputView: View {
    // MARK: - Properties

    /// Existing entries to edit (nil for new entry mode)
    let existingEntries: [MindCheckEntry]?

    /// Callback when user saves their entries
    let onSave: ([MindCheckEntry]) -> Void

    /// Callback when user dismisses without saving
    let onDismiss: () -> Void

    // MARK: - Initialization

    init(
        existingEntries: [MindCheckEntry]? = nil,
        onSave: @escaping ([MindCheckEntry]) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.existingEntries = existingEntries
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    // MARK: - State

    @State private var entries: [MindCheckEntryDraft] = []
    @State private var isInitialized = false
    @FocusState private var focusedEntryId: UUID?

    // MARK: - Private

    private var title: String {
        Strings.MindCheck.morningTitle
    }

    private var subtitle: String {
        Strings.MindCheck.morningSubtitle
    }

    private var hasValidEntries: Bool {
        self.entries.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var entryCountText: String {
        Strings.MindCheck.entryCount(self.entries.count)
    }

    private var canAddMore: Bool {
        self.entries.count < 3
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with subtitle and entry count
                VStack(spacing: 4) {
                    Text(self.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if !self.entries.isEmpty {
                        Text(self.entryCountText)
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 12)

                Divider()

                // Entries list - always show list with add button
                List {
                    ForEach(self.$entries) { $entry in
                        MindCheckEntryRow(
                            entry: $entry,
                            onDelete: { self.deleteEntry(entry) }
                        )
                        .focused(self.$focusedEntryId, equals: entry.id)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    // Add button row at bottom when can add more
                    if self.canAddMore {
                        AddEntryRow {
                            self.addEntry(for: .todo)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle(self.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.MindCheck.cancelButton) {
                        self.onDismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.MindCheck.saveButton) {
                        self.saveEntries()
                    }
                    .disabled(!self.hasValidEntries)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            guard !self.isInitialized else { return }
            self.isInitialized = true

            // Prefill with existing entries if in edit mode
            if let existing = self.existingEntries, !existing.isEmpty {
                self.entries = existing.map { MindCheckEntryDraft(from: $0) }
            }
            // Otherwise start empty - user taps "Add To-Do" to begin
        }
    }

    // MARK: - Actions

    private func addEntry(for category: MindCheckCategory) {
        guard self.entries.count < 3 else { return }

        let newEntry = MindCheckEntryDraft(category: category, text: "")
        self.entries.append(newEntry)

        // Focus the new entry
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.focusedEntryId = newEntry.id
        }
    }

    private func deleteEntry(_ entry: MindCheckEntryDraft) {
        self.entries.removeAll { $0.id == entry.id }
    }

    private func saveEntries() {
        let validEntries = self.entries
            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { draft in
                MindCheckEntry(
                    category: draft.category,
                    text: draft.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    timestamp: Date(),
                    context: .morning
                )
            }

        self.onSave(validEntries)
    }
}

// MARK: - Supporting Views

/// Row for displaying and editing a single entry
private struct MindCheckEntryRow: View {
    @Binding var entry: MindCheckEntryDraft
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Category badge
            Text(self.entry.category.emoji)
                .font(.system(size: 20))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(0.06))
                )

            // Text input
            TextField(self.entry.category.displayName, text: self.$entry.text)
                .font(.body)
                .textFieldStyle(.plain)

            // Delete button
            Button(action: self.onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.03))
        )
    }
}

/// Row for adding a new entry - appears at bottom of list
private struct AddEntryRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: 12) {
                // Plus icon in circle
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)

                // Add text
                Text("Add To-Do")
                    .font(.body)
                    .foregroundColor(.accentColor)

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Draft Model

/// Draft model for in-progress entry editing
struct MindCheckEntryDraft: Identifiable {
    let id: UUID
    var category: MindCheckCategory
    var text: String

    /// Creates a new draft with a fresh UUID
    init(category: MindCheckCategory, text: String) {
        self.id = UUID()
        self.category = category
        self.text = text
    }

    /// Creates a draft from an existing MindCheckEntry for editing
    init(from entry: MindCheckEntry) {
        self.id = entry.id
        self.category = entry.category
        self.text = entry.text
    }
}

// MARK: - Preview

#if DEBUG
    #Preview("Morning Input") {
        MindCheckInputView(
            onSave: { entries in
                print("Saved: \(entries)")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
    }
#endif
