import SwiftUI

/// A tappable pill button displayed on the timeline to prompt mind check input.
/// Appears as a subtle, rounded capsule with an emoji and label.
struct MindCheckPillView: View {
    // MARK: - Properties

    /// The context (morning or evening) this pill is for
    let context: MindCheckContext

    /// Action to perform when tapped
    let action: () -> Void

    // MARK: - Private

    private var emoji: String {
        switch self.context {
        case .morning:
            "🌅"
        case .evening:
            "🌙"
        }
    }

    private var labelText: String {
        switch self.context {
        case .morning:
            "What's on your mind?"
        case .evening:
            "How was your day?"
        }
    }

    private var accessibilityLabel: String {
        switch self.context {
        case .morning:
            "Log morning mind check"
        case .evening:
            "Log evening mind check"
        }
    }

    // MARK: - Body

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: 6) {
                Text(self.emoji)
                    .font(.system(size: 14))

                Text(self.labelText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(self.accessibilityLabel)
        .accessibilityHint("Tap to log your thoughts")
    }
}

// MARK: - Preview

#if DEBUG
    #Preview("Morning Pill") {
        VStack(spacing: 20) {
            MindCheckPillView(context: .morning) {
                print("Morning tapped")
            }

            MindCheckPillView(context: .evening) {
                print("Evening tapped")
            }
        }
        .padding()
    }
#endif
