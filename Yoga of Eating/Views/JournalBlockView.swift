import SwiftUI

struct JournalBlockView: View {
    let meal: Meal
    let isBreathing: Bool
    let onUpdate: (String) -> Void
    @State private var text: String

    init(meal: Meal, isBreathing: Bool, onUpdate: @escaping (String) -> Void) {
        self.meal = meal
        self.isBreathing = isBreathing
        self.onUpdate = onUpdate
        _text = State(initialValue: meal.description)
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
                    TextField("What did you eat?", text: self.$text) {
                        self.onUpdate(self.text)
                    }
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .serif))
                }
            }
            .padding(24)
            .frame(maxWidth: 280, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
            }

            Spacer()
        }
        .padding(.leading, 30) // Position relative to vertical line
    }
}
