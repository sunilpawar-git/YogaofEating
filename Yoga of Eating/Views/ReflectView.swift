import SwiftUI

/// Evening reflection tab: review morning to-dos, free-form journal, and feeling picker.
/// Accepts data via parameters only — never uses @EnvironmentObject.
struct ReflectView: View {
    // MARK: - Input

    let data: ReflectViewContract

    var onJournalTextChanged: ((String) -> Void)?
    var onFeelingChanged: ((ReflectionFeeling?) -> Void)?
    var onTodoToggled: ((UUID) -> Void)?

    // MARK: - Local State

    @State private var journalText: String = ""

    /// Tracks whether the journal field is currently focused so that date navigation
    /// does not reset the journal while the user is actively typing (Issue 4, Option B).
    @FocusState private var isJournalFocused: Bool

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
                    isJournalFocused: self.$isJournalFocused,
                    onChanged: self.onJournalTextChanged
                )

                // Inline signal chips — shown when journal text signals are detected
                if !self.data.detectedSignals.isEmpty {
                    ReflectSignalChipsSection(signals: self.data.detectedSignals)
                }

                Divider().padding(.horizontal)

                // Feeling picker — tapping an emoji also dismisses the keyboard (Issue 5)
                ReflectFeelingSection(
                    selectedFeeling: self.data.feeling,
                    onChanged: { feeling in
                        self.isJournalFocused = false
                        self.onFeelingChanged?(feeling)
                    }
                )

                Spacer(minLength: 60)
            }
            .padding(.top, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            self.journalText = self.data.journalText ?? ""
        }
        .onChange(of: self.data) { _, newData in
            // Option B: don't reset the journal while the user is actively typing.
            if !self.isJournalFocused {
                self.journalText = newData.journalText ?? ""
            }
        }
        .disabled(!self.data.isToday)
        .opacity(self.data.isToday ? 1.0 : 0.7)
    }
}

// MARK: - Signal Chips Section

/// Horizontal row of pill-shaped chips showing detected emotional signals from journal text.
private struct ReflectSignalChipsSection: View {
    let signals: [TextSignal]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Strings.WellbeingBreakdown.detectedSignalsLabel)
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(self.signals, id: \.self) { signal in
                        Text(signal.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AppTheme.cardBackground))
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Focus Field Enum (Reflect)

// ReflectView only has one text entry field, so a simple Bool @FocusState suffices.
// No separate enum is needed.

#Preview {
    ReflectView(
        data: ReflectViewContract(
            journalText: "Today was productive",
            feeling: .calm,
            morningTodos: [
                MindCheckEntry(category: .todo, text: "Exercise", context: .morning),
                MindCheckEntry(category: .todo, text: "Read book", context: .morning)
            ],
            isToday: true,
            detectedSignals: [.clear]
        )
    )
}
