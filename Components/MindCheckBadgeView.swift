import SwiftUI

/// A compact badge showing the completed mind check entries.
/// Displayed on the timeline after user has logged their mind check.
struct MindCheckBadgeView: View {
    // MARK: - Properties

    /// The entries to display
    let entries: [MindCheckEntry]

    /// The context (morning or evening)
    let context: MindCheckContext

    /// Optional tap action to expand/view details
    var onTap: (() -> Void)?

    // MARK: - Private

    private var emoji: String {
        switch self.context {
        case .morning:
            "🌅"
        case .evening:
            "🌙"
        }
    }

    private var summaryText: String {
        let count = self.entries.count
        switch count {
        case 1:
            return self.entries.first?.text ?? "1 thought"
        case 2, 3:
            return "\(count) thoughts logged"
        default:
            return "Mind check complete"
        }
    }

    // MARK: - Body

    var body: some View {
        Button {
            self.onTap?()
        } label: {
            HStack(spacing: 6) {
                // Category emojis
                HStack(spacing: -4) {
                    ForEach(self.entries.prefix(3)) { entry in
                        Text(entry.category.emoji)
                            .font(.system(size: 12))
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }
                }

                // Summary text
                Text(self.summaryText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mind check complete: \(self.entries.count) entries")
    }
}

// MARK: - Preview

#if DEBUG
    #Preview("Single Entry") {
        MindCheckBadgeView(
            entries: [
                MindCheckEntry(
                    category: .todo,
                    text: "Buy groceries",
                    timestamp: Date(),
                    context: .morning
                )
            ],
            context: .morning
        )
        .padding()
    }

    #Preview("Multiple Entries") {
        MindCheckBadgeView(
            entries: [
                MindCheckEntry(category: .todo, text: "Task 1", timestamp: Date(), context: .morning),
                MindCheckEntry(category: .gratitude, text: "Health", timestamp: Date(), context: .morning),
                MindCheckEntry(category: .thinking, text: "Future", timestamp: Date(), context: .morning)
            ],
            context: .morning
        )
        .padding()
    }
#endif
