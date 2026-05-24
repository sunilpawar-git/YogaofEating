import SwiftUI

/// Plain duration label centered on the timeline connector between meals.
/// Shows elapsed time (e.g. "4h 55m") without decorative capsule or glow —
/// the spine carries the visual; this label just adds the temporal context.
struct FastingBadgeView: View {
    let fastingPeriod: FastingPeriod

    /// Text shown in the connector. Exposed for testing.
    var displayText: String { self.fastingPeriod.formattedDuration }

    var body: some View {
        Text(self.displayText)
            .font(FontTheme.caption)
            .foregroundColor(.secondary.opacity(0.7))
            .accessibilityLabel("Fasting period: \(self.displayText)")
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
