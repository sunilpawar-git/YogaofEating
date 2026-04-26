import SwiftUI

struct EveningReviewTextInputSection: View {
    let emoji: String
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(self.emoji)
                    .font(.title3)
                Text(self.title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            TextField(self.placeholder, text: self.$text, axis: .vertical)
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
                .lineLimit(3...5)
        }
    }
}

struct EveningReviewTodoCheckboxRow: View {
    let todo: MindCheckEntry
    @Binding var isAccomplished: Bool

    var body: some View {
        Button {
            self.isAccomplished.toggle()
            SensoryService.shared.playNudge(style: .light)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: self.isAccomplished ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(self.isAccomplished ? .green : .secondary.opacity(0.5))

                Text(self.todo.text)
                    .font(.body)
                    .foregroundColor(self.isAccomplished ? .secondary : .primary)
                    .strikethrough(self.isAccomplished, color: .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                Text(
                    self.isAccomplished
                        ? Strings.MindCheck.EveningReview.accomplished
                        : Strings.MindCheck.EveningReview.notAccomplished
                )
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
        .accessibilityLabel(Strings.MindCheck.EveningReview.accessibilityLabel(
            self.todo.text,
            accomplished: self.isAccomplished
        ))
        .accessibilityHint(Strings.MindCheck.EveningReview.toggleHint)
    }
}

struct EveningReviewFeelingButton: View {
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
#endif
