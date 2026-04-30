import SwiftUI

// MARK: - HealthKit Card

struct HighlightHealthKitCard: View {
    let sleepData: SleepData

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "applewatch")
                .font(.title3)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Apple Sleep")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Text(self.sleepData.formattedDuration)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let score = self.sleepData.sleepScore {
                        Text("\(Int(score))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            if let quality = self.sleepData.sleepQuality {
                Text(quality.emoji)
                    .font(.title2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.blue.opacity(0.06))
        )
        .padding(.horizontal)
    }
}

// MARK: - Sleep Section

struct HighlightSleepSection: View {
    let selectedQuality: SleepQuality?
    @Binding var sleepNotesText: String
    var onQualityChanged: ((SleepQuality?) -> Void)?
    var onNotesChanged: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Sleep", systemImage: "moon.zzz.fill")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 14) {
                ForEach(SleepQuality.allCases, id: \.self) { quality in
                    self.qualityButton(quality)
                }
            }
            .padding(.horizontal)

            TextField("How was your sleep?", text: self.$sleepNotesText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(2...4)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal)
                .onChange(of: self.sleepNotesText) { _, newValue in
                    self.onNotesChanged?(newValue)
                }
        }
    }

    private func qualityButton(_ quality: SleepQuality) -> some View {
        let isSelected = self.selectedQuality == quality

        return Button {
            self.onQualityChanged?(isSelected ? nil : quality)
            SensoryService.shared.playNudge(style: .light)
        } label: {
            VStack(spacing: 4) {
                Text(quality.emoji)
                    .font(.system(size: 30))
                Text(quality.displayName)
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
        .accessibilityIdentifier("highlight-sleep-\(quality.rawValue)")
    }
}

// MARK: - To-Do Section

struct HighlightTodoSection: View {
    let todos: [MindCheckEntry]
    @Binding var newTodoText: String
    var onAddTodo: ((String) -> Void)?
    var onRemoveTodo: ((UUID) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("To-Do", systemImage: "checklist")
                .font(.headline)
                .padding(.horizontal)

            ForEach(self.todos) { todo in
                HStack(spacing: 10) {
                    Text(todo.category.emoji)
                        .font(.system(size: 18))
                    Text(todo.text)
                        .font(.body)
                        .lineLimit(2)
                    Spacer()
                    Button { self.onRemoveTodo?(todo.id) } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary.opacity(0.4))
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.03))
                )
                .padding(.horizontal)
            }

            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 20))

                TextField("Add a to-do", text: self.$newTodoText)
                    .textFieldStyle(.plain)
                    .onSubmit { self.submitTodo() }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.accentColor.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
        }
    }

    private func submitTodo() {
        let trimmed = self.newTodoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        self.onAddTodo?(trimmed)
        self.newTodoText = ""
    }
}

// MARK: - Morning Thoughts Section

struct HighlightThoughtsSection: View {
    @Binding var text: String
    var onChanged: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Morning Thoughts", systemImage: "text.bubble")
                .font(.headline)
                .padding(.horizontal)

            TextEditor(text: self.$text)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
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
                        Text("What's on your mind this morning?")
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal)
                .onChange(of: self.text) { _, newValue in
                    self.onChanged?(newValue)
                }
        }
    }
}
