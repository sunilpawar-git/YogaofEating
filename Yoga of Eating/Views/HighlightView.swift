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
                    focusedField: self.$focusedField,
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
        .onChange(of: self.data.date) { _, _ in
            // Re-initialize text only when the selected date changes (e.g. date navigation).
            // Reacting to self.data directly caused text to vanish: any same-day background
            // mutation (HealthKit callback, Firestore sync, quality tap) would fire this
            // handler while the debounce hadn't saved yet, resetting in-progress text to nil.
            self.sleepNotesText = self.data.sleepNotes ?? ""
            self.morningThoughtsText = self.data.morningThoughts ?? ""
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
    case todo
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
            isToday: true,
            date: Calendar.current.startOfDay(for: Date())
        )
    )
}
