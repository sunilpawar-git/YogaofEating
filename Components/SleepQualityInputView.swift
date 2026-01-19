import SwiftUI

/// Compact horizontal picker for sleep quality.
/// Designed for quick single-tap selection with auto-dismiss.
struct SleepQualityInputView: View {
    /// Callback when user selects a sleep quality
    let onSelect: (SleepQuality) -> Void

    /// Callback when user dismisses without selection
    let onDismiss: () -> Void

    /// Optional suggested sleep quality from Apple HealthKit
    let suggestedQuality: SleepQuality?

    /// Optional sleep data from HealthKit (for display)
    let sleepData: SleepData?

    init(
        onSelect: @escaping (SleepQuality) -> Void,
        onDismiss: @escaping () -> Void,
        suggestedQuality: SleepQuality? = nil,
        sleepData: SleepData? = nil
    ) {
        self.onSelect = onSelect
        self.onDismiss = onDismiss
        self.suggestedQuality = suggestedQuality
        self.sleepData = sleepData
    }

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

                // Show Apple HealthKit suggestion if available
                if let suggested = self.suggestedQuality, let data = self.sleepData {
                    HStack(spacing: 4) {
                        Image(systemName: "applewatch")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("Apple suggests: \(suggested.displayName)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        if let score = data.sleepScore {
                            Text("(\(Int(score))%)")
                                .font(.caption2)
                                .foregroundColor(.blue.opacity(0.7))
                        }
                    }
                    .padding(.top, 4)
                }
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
        let isSuggested = quality == self.suggestedQuality

        return Button {
            self.onSelect(quality)
        } label: {
            VStack(spacing: 6) {
                Text(quality.emoji)
                    .font(.system(size: 36))

                Text(quality.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                // Show indicator if this is Apple's suggestion
                if isSuggested {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSuggested ? Color.blue.opacity(0.1) : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSuggested ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
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
        },
        suggestedQuality: .good,
        sleepData: nil
    )
}
