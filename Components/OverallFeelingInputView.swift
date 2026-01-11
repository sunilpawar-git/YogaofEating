import SwiftUI

/// Compact horizontal picker for overall feeling.
/// Designed for quick single-tap selection with auto-dismiss.
struct OverallFeelingInputView: View {
    /// Callback when user selects a feeling
    let onSelect: (ReflectionFeeling) -> Void

    /// Callback when user dismisses without selection
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 4) {
                Text("🌙")
                    .font(.system(size: 32))

                Text("End of day")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("How did you feel today?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)

            // Feeling options - horizontal row
            HStack(spacing: 12) {
                ForEach(ReflectionFeeling.allCases, id: \.self) { feeling in
                    self.feelingButton(feeling)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            // Skip button
            Button("Skip") {
                self.onDismiss()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("overall-feeling-input")
    }

    private func feelingButton(_ feeling: ReflectionFeeling) -> some View {
        Button {
            self.onSelect(feeling)
        } label: {
            VStack(spacing: 6) {
                Text(feeling.emoji)
                    .font(.system(size: 32))

                Text(feeling.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(width: 60, height: 65)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("feeling-\(feeling.rawValue)")
    }
}

#Preview {
    OverallFeelingInputView(
        onSelect: { feeling in
            print("Selected: \(feeling)")
        },
        onDismiss: {
            print("Dismissed")
        }
    )
}
