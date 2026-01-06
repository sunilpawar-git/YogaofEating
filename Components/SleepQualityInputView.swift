import SwiftUI

/// Compact horizontal picker for sleep quality.
/// Designed for quick single-tap selection with auto-dismiss.
struct SleepQualityInputView: View {
    /// Callback when user selects a sleep quality
    let onSelect: (SleepQuality) -> Void

    /// Callback when user dismisses without selection
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 4) {
                Text("☀️")
                    .font(.system(size: 32))

                Text("Good morning!")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("How did you sleep?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)

            // Sleep quality options - horizontal row
            HStack(spacing: 16) {
                ForEach(SleepQuality.allCases, id: \.self) { quality in
                    self.sleepQualityButton(quality)
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
        .accessibilityIdentifier("sleep-quality-input")
    }

    private func sleepQualityButton(_ quality: SleepQuality) -> some View {
        Button {
            self.onSelect(quality)
        } label: {
            VStack(spacing: 6) {
                Text(quality.emoji)
                    .font(.system(size: 36))

                Text(quality.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("sleep-quality-\(quality.rawValue)")
    }
}

#Preview {
    SleepQualityInputView(
        onSelect: { quality in
            print("Selected: \(quality)")
        },
        onDismiss: {
            print("Dismissed")
        }
    )
}
