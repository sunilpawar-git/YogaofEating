import SwiftUI

/// A subtle inline badge displaying sleep quality or overall feeling.
/// Designed to be minimalist and blend with the timeline aesthetic.
struct ReflectionBadgeView: View {
    /// The type of reflection to display
    let type: ReflectionType

    /// Whether the badge is tappable (for editing)
    let isTappable: Bool

    /// Optional callback when badge is tapped
    var onTap: (() -> Void)?

    enum ReflectionType {
        case sleep(SleepQuality)
        case feeling(ReflectionFeeling)

        var emoji: String {
            switch self {
            case let .sleep(quality): quality.emoji
            case let .feeling(feeling): feeling.emoji
            }
        }

        var displayText: String {
            switch self {
            case let .sleep(quality): quality.displayName
            case let .feeling(feeling): feeling.displayName
            }
        }

        var accessibilityLabel: String {
            switch self {
            case let .sleep(quality): "Sleep quality: \(quality.displayName)"
            case let .feeling(feeling): "Overall feeling: \(feeling.displayName)"
            }
        }

        var accessibilityIdentifier: String {
            switch self {
            case .sleep: "sleep-badge"
            case .feeling: "feeling-badge"
            }
        }
    }

    var body: some View {
        if self.isTappable, let onTap = self.onTap {
            Button(action: onTap) {
                self.badgeContent
            }
            .buttonStyle(.plain)
        } else {
            self.badgeContent
        }
    }

    private var badgeContent: some View {
        HStack(spacing: 4) {
            Text(self.type.emoji)
                .font(.system(size: 14))

            Text(self.type.displayText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.primary.opacity(0.06))
        )
        .accessibilityLabel(self.type.accessibilityLabel)
        .accessibilityIdentifier(self.type.accessibilityIdentifier)
    }
}

// MARK: - Preview

#Preview("Sleep Badge") {
    VStack(spacing: 16) {
        ReflectionBadgeView(type: .sleep(.great), isTappable: false)
        ReflectionBadgeView(type: .sleep(.good), isTappable: false)
        ReflectionBadgeView(type: .sleep(.poor), isTappable: false)
        ReflectionBadgeView(type: .sleep(.terrible), isTappable: false)
    }
    .padding()
}

#Preview("Feeling Badge") {
    VStack(spacing: 16) {
        ReflectionBadgeView(type: .feeling(.great), isTappable: false)
        ReflectionBadgeView(type: .feeling(.calm), isTappable: false)
        ReflectionBadgeView(type: .feeling(.ok), isTappable: false)
        ReflectionBadgeView(type: .feeling(.tired), isTappable: false)
        ReflectionBadgeView(type: .feeling(.heavy), isTappable: false)
    }
    .padding()
}

#Preview("Tappable Badge") {
    ReflectionBadgeView(
        type: .sleep(.good),
        isTappable: true,
        onTap: { print("Tapped!") }
    )
    .padding()
}
