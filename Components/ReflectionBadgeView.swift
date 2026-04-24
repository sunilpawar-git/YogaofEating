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

    /// Optional Apple HealthKit sleep data for enhanced display
    /// When available, shows additional metrics (score, duration) for sleep badges
    var sleepData: SleepData?

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
        VStack(spacing: 2) {
            // First line: "Sleep 😴 : Good" or "Feeling 🤔 : Great"
            self.primaryBadgeLine

            // Second line (only for sleep badges with Apple data): "⌚ : 85% • 7h 30m"
            if self.shouldShowAppleMetrics {
                self.appleMetricsLine
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, self.shouldShowAppleMetrics ? 8 : 6)
        .background(
            RoundedRectangle(cornerRadius: self.shouldShowAppleMetrics ? 12 : 20)
                .fill(Color.primary.opacity(0.06))
        )
        .accessibilityLabel(self.fullAccessibilityLabel)
        .accessibilityIdentifier(self.type.accessibilityIdentifier)
    }

    /// The primary line showing sleep quality or feeling
    private var primaryBadgeLine: some View {
        HStack(spacing: 4) {
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
    }

    /// The Apple Watch metrics line (score and duration)
    private var appleMetricsLine: some View {
        HStack(spacing: 4) {
            Text("⌚")
                .font(.system(size: 10))

            Text(":")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.6))

            if let score = self.sleepData?.sleepScore {
                Text("\(Int(score))%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue.opacity(0.8))
            }

            if let duration = self.sleepData?.formattedDuration {
                Text("•")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.4))

                Text(duration)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    /// Whether to show Apple Watch metrics (only for sleep badges with score)
    private var shouldShowAppleMetrics: Bool {
        guard case .sleep = self.type else { return false }
        return self.sleepData?.sleepScore != nil
    }

    /// Full accessibility label including Apple metrics if available
    private var fullAccessibilityLabel: String {
        var label = self.type.accessibilityLabel

        if self.shouldShowAppleMetrics, let score = self.sleepData?.sleepScore {
            label += ", Apple Watch: \(Int(score))%"

            if let duration = self.sleepData?.formattedDuration {
                label += ", Duration: \(duration)"
            }
        }

        return label
    }
}

// MARK: - Preview

#Preview("Sleep Badge - No Apple Data") {
    VStack(spacing: 16) {
        ReflectionBadgeView(type: .sleep(.great), isTappable: false)
        ReflectionBadgeView(type: .sleep(.good), isTappable: false)
        ReflectionBadgeView(type: .sleep(.poor), isTappable: false)
        ReflectionBadgeView(type: .sleep(.terrible), isTappable: false)
    }
    .padding()
}

#Preview("Sleep Badge - With Apple Data") {
    VStack(spacing: 16) {
        ReflectionBadgeView(
            type: .sleep(.great),
            isTappable: false,
            sleepData: SleepData(
                sleepDuration: 8 * 3600,
                timeInBed: 8.5 * 3600,
                sleepStart: nil,
                sleepEnd: nil,
                sleepScore: 92
            )
        )
        ReflectionBadgeView(
            type: .sleep(.good),
            isTappable: false,
            sleepData: SleepData(
                sleepDuration: 7 * 3600,
                timeInBed: 8 * 3600,
                sleepStart: nil,
                sleepEnd: nil,
                sleepScore: 75
            )
        )
        ReflectionBadgeView(
            type: .sleep(.poor),
            isTappable: false,
            sleepData: SleepData(
                sleepDuration: 5.5 * 3600,
                timeInBed: 7 * 3600,
                sleepStart: nil,
                sleepEnd: nil,
                sleepScore: 45
            )
        )
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

#Preview("Tappable Badge - With Apple Data") {
    ReflectionBadgeView(
        type: .sleep(.good),
        isTappable: true,
        onTap: { print("Tapped!") },
        sleepData: SleepData(
            sleepDuration: 7.5 * 3600,
            timeInBed: 8 * 3600,
            sleepStart: nil,
            sleepEnd: nil,
            sleepScore: 85
        )
    )
    .padding()
}
