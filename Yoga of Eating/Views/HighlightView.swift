import SwiftUI

/// Morning journal tab: sleep quality, sleep notes, to-do items, and free-form thoughts.
/// Accepts data via parameters only — never uses @EnvironmentObject.
struct HighlightView: View {
    let data: HighlightViewContract

    var onSleepQualityChanged: ((SleepQuality?) -> Void)?
    var onSleepNotesChanged: ((String) -> Void)?
    var onTodosChanged: (([MindCheckEntry]) -> Void)?
    var onAddTodo: ((String) -> Void)?
    var onRemoveTodo: ((UUID) -> Void)?
    var onMorningThoughtsChanged: ((String) -> Void)?

    @State private var sleepNotesText: String = ""
    @State private var morningThoughtsText: String = ""
    @State private var newTodoText: String = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                if let sleepData = self.data.healthKitSleepData {
                    HighlightHealthKitCard(sleepData: sleepData)
                }

                HighlightSleepSection(
                    selectedQuality: self.data.sleepQuality,
                    sleepNotesText: self.$sleepNotesText,
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
                    onChanged: self.onMorningThoughtsChanged
                )

                Spacer(minLength: 60)
            }
            .padding(.top, 16)
        }
        // Tap anywhere outside a text field to dismiss the keyboard
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            self.sleepNotesText = self.data.sleepNotes ?? ""
            self.morningThoughtsText = self.data.morningThoughts ?? ""
        }
        .onChange(of: self.data) { _, newData in
            self.sleepNotesText = newData.sleepNotes ?? ""
            self.morningThoughtsText = newData.morningThoughts ?? ""
        }
        .disabled(!self.data.isToday)
        .opacity(self.data.isToday ? 1.0 : 0.7)
    }
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
