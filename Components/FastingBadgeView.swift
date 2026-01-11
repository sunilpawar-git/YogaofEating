import SwiftUI

/// Minimalist badge displaying fasting duration, centered on timeline connector.
/// Shows subtle glow effect for longer fasting periods (12h+).
struct FastingBadgeView: View {
    let fastingPeriod: FastingPeriod

    var body: some View {
        Text("[\(self.fastingPeriod.formattedDuration)]")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundColor(.secondary.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                Capsule()
                    .stroke(self.borderColor, lineWidth: 0.5)
            }
            .shadow(
                color: self.glowColor.opacity(self.fastingPeriod.glowIntensity * 0.4),
                radius: self.glowRadius,
                x: 0,
                y: 0
            )
            .accessibilityLabel("Fasting period: \(self.fastingPeriod.formattedDuration)")
    }

    /// Border color based on fasting significance
    private var borderColor: Color {
        self.fastingPeriod.isSignificant
            ? Color.green.opacity(0.4)
            : Color.primary.opacity(0.1)
    }

    /// Glow color for significant fasting periods
    private var glowColor: Color {
        .green
    }

    /// Glow radius scales with intensity
    private var glowRadius: CGFloat {
        self.fastingPeriod.isSignificant ? 8 : 0
    }
}

#Preview("Short Fasting") {
    VStack {
        FastingBadgeView(
            fastingPeriod: FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: Date(),
                endTime: Date().addingTimeInterval(4 * 3600) // 4h
            )
        )
    }
    .padding()
    .background(Color.black)
}

#Preview("Long Fasting (16h)") {
    VStack {
        FastingBadgeView(
            fastingPeriod: FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: Date(),
                endTime: Date().addingTimeInterval(16 * 3600) // 16h
            )
        )
    }
    .padding()
    .background(Color.black)
}

#Preview("Max Fasting (20h+)") {
    VStack {
        FastingBadgeView(
            fastingPeriod: FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: Date(),
                endTime: Date().addingTimeInterval(22 * 3600) // 22h
            )
        )
    }
    .padding()
    .background(Color.black)
}

