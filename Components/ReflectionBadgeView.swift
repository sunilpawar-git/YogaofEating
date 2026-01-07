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

        /// Fixed icon for the badge type (not value-dependent)
        var fixedIcon: String {
            switch self {
            case .sleep: "😴" // Always sleepy face for sleep
            case .feeling: "🤔" // Always thinking face for feeling
            }
        }

        /// Label prefix for the badge
        var label: String {
            switch self {
            case .sleep: "Sleep"
            case .feeling: "Feeling"
            }
        }

        /// The value text (e.g., "Good", "Great")
        var valueText: String {
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
            // Format: "Label (fixed-icon) : Value"
            // e.g., "Sleep 😴 : Good" or "Feeling 🤔 : Great"
            Text(self.type.label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Text(self.type.fixedIcon)
                .font(.system(size: 12))

            Text(":")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.6))

            Text(self.type.valueText)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.primary.opacity(0.8))
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
