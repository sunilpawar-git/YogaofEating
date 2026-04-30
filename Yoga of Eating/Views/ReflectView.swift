import SwiftUI

/// Evening reflection tab: review morning to-dos, free-form journal, and feeling picker.
/// Accepts data via parameters only — never uses @EnvironmentObject.
struct ReflectView: View {
    let data: ReflectViewContract

    var onJournalTextChanged: ((String) -> Void)?
    var onFeelingChanged: ((ReflectionFeeling?) -> Void)?
    var onTodoToggled: ((UUID) -> Void)?

    @State private var journalText: String = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Morning to-do review
                ReflectTodoReviewSection(
                    todos: self.data.morningTodos,
                    onToggle: self.onTodoToggled
                )

                Divider().padding(.horizontal)

                // Journal section
                ReflectJournalSection(
                    text: self.$journalText,
                    onChanged: self.onJournalTextChanged
                )

                Divider().padding(.horizontal)

                // Feeling picker
                ReflectFeelingSection(
                    selectedFeeling: self.data.feeling,
                    onChanged: self.onFeelingChanged
                )

                Spacer(minLength: 60)
            }
            .padding(.top, 16)
        }
        .onAppear {
            self.journalText = self.data.journalText ?? ""
        }
        .onChange(of: self.data) { _, newData in
            self.journalText = newData.journalText ?? ""
        }
        .disabled(!self.data.isToday)
        .opacity(self.data.isToday ? 1.0 : 0.7)
    }
}

#Preview {
    ReflectView(
        data: ReflectViewContract(
            journalText: "Today was productive",
            feeling: .calm,
            morningTodos: [
                MindCheckEntry(category: .todo, text: "Exercise", context: .morning),
                MindCheckEntry(category: .todo, text: "Read book", context: .morning)
            ],
            isToday: true
        )
    )
}
