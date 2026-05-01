import SwiftUI

/// Morning journal tab: sleep quality, sleep notes, to-do items, and free-form thoughts.
/// Accepts data via parameters only — never uses @EnvironmentObject.
struct HighlightView: View {
    // MARK: - Input

    let data: HighlightViewContract

    var onSleepQualityChanged: ((SleepQuality?) -> Void)?
    var onSleepNotesChanged: ((String) -> Void)?
    var onTodosChanged: (([MindCheckEntry]) -> Void)?
    var onAddTodo: ((String) -> Void)?
    var onRemoveTodo: ((UUID) -> Void)?
    var onMorningThoughtsChanged: ((String) -> Void)?

    // MARK: - Local State

    @State private var sleepNotesText: String = ""
    @State private var morningThoughtsText: String = ""
    @State private var newTodoText: String = ""

    /// Tracks which text field is currently focused so that date navigation
    /// does not reset a field the user is actively typing in (Issue 4, Option B).
    @FocusState private var focusedField: HighlightFocusField?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                if let sleepData = self.data.healthKitSleepData {
                    HighlightHealthKitCard(sleepData: sleepData)
                }

                HighlightSleepSection(
                    selectedQuality: self.data.sleepQuality,
                    sleepNotesText: self.$sleepNotesText,
                    focusedField: self.$focusedField,
                    onQualityChanged: self.onSleepQualityChanged,
                    onNotesChanged: self.onSleepNotesChanged
                )

                Divider().padding(.horizontal)

                HighlightTodoSection(
                    todos: self.data.todos,
                    newTodoText: self.$newTodoText,
                    onAddTodo: self.onAddTodo,
                    onRemoveTodo: self.onRemoveTodo
                )

                Divider().padding(.horizontal)

                HighlightThoughtsSection(
                    text: self.$morningThoughtsText,
                    focusedField: self.$focusedField,
                    onChanged: self.onMorningThoughtsChanged
                )

                Spacer(minLength: 60)
            }
            .padding(.top, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            self.sleepNotesText = self.data.sleepNotes ?? ""
            self.morningThoughtsText = self.data.morningThoughts ?? ""
        }
        .onChange(of: self.data) { _, newData in
            // Option B: skip resetting a field if the user is currently typing in it.
            if self.focusedField != .sleepNotes {
                self.sleepNotesText = newData.sleepNotes ?? ""
            }
            if self.focusedField != .morningThoughts {
                self.morningThoughtsText = newData.morningThoughts ?? ""
            }
        }
        .disabled(!self.data.isToday)
        .opacity(self.data.isToday ? 1.0 : 0.7)
    }
}

// MARK: - Focus Field Enum

/// Identifies which text field in HighlightView is currently focused.
enum HighlightFocusField: Hashable {
    case sleepNotes
    case morningThoughts
}

#Preview {
    HighlightView(
        data: HighlightViewContract(
            sleepQuality: .good,
            sleepNotes: "Slept well",
            todos: [
                MindCheckEntry(category: .todo, text: "Meditate", context: .morning),
                MindCheckEntry(category: .todo, text: "Read", context: .morning)
            ],
            morningThoughts: "Feeling rested and ready",
            healthKitSleepData: nil,
            isToday: true
        )
    )
}
