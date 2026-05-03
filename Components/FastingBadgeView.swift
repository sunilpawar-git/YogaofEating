import SwiftUI

/// Minimalist badge displaying fasting duration, centered on timeline connector.
/// Significant fasting periods (12h+) display with green text and a subtle green
/// capsule wash to express their metabolic significance. Default periods stay grey.
struct FastingBadgeView: View {
    let fastingPeriod: FastingPeriod

    var body: some View {
        Text("[\(self.fastingPeriod.formattedDuration)]")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundColor(self.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(self.capsuleFill)
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

    /// Text color: green for significant periods, default secondary for others.
    private var textColor: Color {
        self.fastingPeriod.isSignificant
            ? AppTheme.Timeline.fastingSignificantColor
            : AppTheme.Timeline.fastingDefaultColor
    }

    /// Capsule fill: subtle green wash for significant periods, material for others.
    private var capsuleFill: AnyShapeStyle {
        if self.fastingPeriod.isSignificant {
            return AnyShapeStyle(
                AppTheme.Timeline.fastingSignificantColor
                    .opacity(AppTheme.Timeline.fastingSignificantFillOpacity)
            )
        }
        return AnyShapeStyle(.ultraThinMaterial)
    }

    /// Border color based on fasting significance.
    private var borderColor: Color {
        self.fastingPeriod.isSignificant
            ? AppTheme.Timeline.fastingSignificantColor.opacity(0.4)
            : Color.primary.opacity(0.1)
    }

    /// Glow color for significant fasting periods.
    private var glowColor: Color {
        .green
    }

    /// Glow radius scales with intensity.
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
