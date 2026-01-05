import SwiftUI

/// A minimalist bottom sheet for capturing end-of-day reflection.
/// Allows users to log how their eating made them feel and optionally their sleep quality.
struct EndOfDayReflectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool

    /// Callback when user saves their reflection
    var onSave: (DailyReflection) -> Void

    /// Callback when user skips reflection
    var onSkip: () -> Void

    // MARK: - State

    @State private var selectedFeeling: ReflectionFeeling?
    @State private var selectedSleepQuality: SleepQuality?
    @State private var note: String = ""
    @FocusState private var isNoteFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    self.headerSection
                    self.feelingSection
                    self.sleepSection
                    self.noteSection
                    self.actionButtons
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(self.backgroundGradient)
            .navigationTitle("Daily Reflection")
            #if canImport(UIKit)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Skip") {
                            self.onSkip()
                            self.isPresented = false
                        }
                        .foregroundColor(.secondary)
                    }
                }
        }
        .accessibilityIdentifier("end-of-day-reflection-view")
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("How did today's eating make you feel?")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("Take a moment to reflect on your body's response")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Feeling Section

    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Feeling")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                ForEach(ReflectionFeeling.allCases, id: \.self) { feeling in
                    self.feelingButton(for: feeling)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func feelingButton(for feeling: ReflectionFeeling) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.selectedFeeling = feeling
            }
            SensoryService.shared.playNudge(style: .light)
        } label: {
            VStack(spacing: 6) {
                Text(feeling.emoji)
                    .font(.system(size: 32))

                Text(feeling.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(self.selectedFeeling == feeling
                        ? self.feelingColor(for: feeling).opacity(0.2)
                        : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        self.selectedFeeling == feeling
                            ? self.feelingColor(for: feeling)
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("feeling-\(feeling.rawValue)")
        .accessibilityLabel("\(feeling.displayName) feeling")
    }

    private func feelingColor(for feeling: ReflectionFeeling) -> Color {
        switch feeling {
        case .great, .calm:
            .green
        case .ok:
            .blue
        case .tired, .heavy:
            .orange
        }
    }

    // MARK: - Sleep Section

    private var sleepSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Sleep Quality")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("(Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                ForEach(SleepQuality.allCases, id: \.self) { quality in
                    self.sleepButton(for: quality)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func sleepButton(for quality: SleepQuality) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if self.selectedSleepQuality == quality {
                    self.selectedSleepQuality = nil // Deselect if tapped again
                } else {
                    self.selectedSleepQuality = quality
                }
            }
            SensoryService.shared.playNudge(style: .soft)
        } label: {
            VStack(spacing: 6) {
                Text(quality.emoji)
                    .font(.system(size: 28))

                Text(quality.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(self.selectedSleepQuality == quality
                        ? Color.purple.opacity(0.2)
                        : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        self.selectedSleepQuality == quality
                            ? Color.purple
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("sleep-\(quality.rawValue)")
        .accessibilityLabel("\(quality.displayName) sleep quality")
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("(Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            TextField("Any thoughts about today's eating...", text: self.$note, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(12)
                .lineLimit(3...6)
                .focused(self.$isNoteFocused)
                .accessibilityIdentifier("reflection-note-field")
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                self.saveReflection()
            } label: {
                Text("Save Reflection")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(self.selectedFeeling != nil
                                ? Color.green
                                : Color.gray.opacity(0.5))
                    )
            }
            .disabled(self.selectedFeeling == nil)
            .accessibilityIdentifier("save-reflection-button")

            Text("Your reflection helps track how food affects your wellbeing")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            #if canImport(UIKit)
                Color(uiColor: .systemBackground)
            #elseif canImport(AppKit)
                Color(nsColor: .controlBackgroundColor)
            #endif

            LinearGradient(
                colors: [
                    Color.purple.opacity(0.03),
                    Color.blue.opacity(0.02),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Actions

    private func saveReflection() {
        guard let feeling = self.selectedFeeling else { return }

        let reflection = DailyReflection(
            feeling: feeling,
            sleepQuality: self.selectedSleepQuality,
            note: self.note.isEmpty ? nil : self.note
        )

        SensoryService.shared.playNudge(style: .medium)
        self.onSave(reflection)
        self.isPresented = false
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var isPresented = true

        var body: some View {
            Color.clear
                .sheet(isPresented: self.$isPresented) {
                    EndOfDayReflectionView(
                        isPresented: self.$isPresented,
                        onSave: { reflection in
                            print("Saved: \(reflection)")
                        },
                        onSkip: {
                            print("Skipped")
                        }
                    )
                    .presentationDetents([.medium, .large])
                }
        }
    }

    return PreviewWrapper()
}
