import SwiftUI

/// Morning Reflect input sheet for energy level and daily eating intention.
/// Presented after sleep quality is logged if no intention exists for today.
struct ReflectInputView: View {
    let onSave: (_ energy: Int, _ intention: String) -> Void
    let onDismiss: () -> Void

    @State private var energyLevel: Int = 3
    @State private var intention: String = ""
    @FocusState private var isIntentionFocused: Bool

    private let energyEmojis = Strings.Reflect.energyEmojis
    private let energyLabels = Strings.Reflect.energyLabels
    private let maxIntentionLength = 140

    var body: some View {
        VStack(spacing: 24) {
            self.header

            self.energySelector

            self.intentionField

            self.buttons
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 4) {
            Text("🌅")
                .font(.system(size: 32))

            Text(Strings.Reflect.title)
                .font(.title3)
                .fontWeight(.semibold)

            Text(Strings.Reflect.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var energySelector: some View {
        VStack(spacing: 8) {
            Text(Strings.Reflect.energyLabel)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            self.energyLevel = level
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(self.energyEmojis[level - 1])
                                .font(.system(size: self.energyLevel == level ? 30 : 24))

                            Text(self.energyLabels[level - 1])
                                .font(.caption2)
                                .foregroundColor(self.energyLevel == level ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(self.energyLevel == level ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(self.energyLevel == level ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(self.energyLabels[level - 1]) energy, level \(level)")
                    .accessibilityAddTraits(self.energyLevel == level ? .isSelected : [])
                }
            }
        }
    }

    private var intentionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Strings.Reflect.intentionLabel)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            TextField(Strings.Reflect.intentionPlaceholder, text: self.$intention, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...3)
                .focused(self.$isIntentionFocused)
                .onChange(of: self.intention) { _, newValue in
                    if newValue.count > self.maxIntentionLength {
                        self.intention = String(newValue.prefix(self.maxIntentionLength))
                    }
                }

            HStack {
                Spacer()
                Text("\(self.intention.count)/\(self.maxIntentionLength)")
                    .font(.caption2)
                    .foregroundColor(self.intention.count > self.maxIntentionLength - 20 ? .orange : .secondary)
            }
        }
    }

    private var buttons: some View {
        HStack(spacing: 16) {
            Button(Strings.Reflect.skipButton) {
                self.onDismiss()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Spacer()

            Button {
                let trimmedIntention = self.intention.trimmingCharacters(in: .whitespacesAndNewlines)
                self.onSave(
                    self.energyLevel,
                    trimmedIntention.isEmpty ? Strings.Reflect.defaultIntention : trimmedIntention
                )
            } label: {
                Text(Strings.Reflect.saveButton)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
    }
}
