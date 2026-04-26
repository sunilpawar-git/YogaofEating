import SwiftUI

/// A 4-segment circular progress ring showing daily module completion.
/// Each arc represents one module: Reflect, Laser, Highlight, Energise.
struct DayRingView: View {
    let progress: DayModuleProgress
    var ringSize: CGFloat = 56
    var lineWidth: CGFloat = 5

    @State private var animatedProgress = DayModuleProgress.empty

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: self.lineWidth)

            // Module arcs (each takes a quarter of the ring)
            self.arcSegment(
                progress: self.animatedProgress.reflectProgress,
                startAngle: 0,
                color: Self.reflectColor
            )
            self.arcSegment(
                progress: self.animatedProgress.laserProgress,
                startAngle: 90,
                color: Self.laserColor
            )
            self.arcSegment(
                progress: self.animatedProgress.highlightProgress,
                startAngle: 180,
                color: Self.highlightColor
            )
            self.arcSegment(
                progress: self.animatedProgress.energiseProgress,
                startAngle: 270,
                color: Self.energiseColor
            )

            // Center percentage
            Text("\(Int(self.animatedProgress.overallProgress * 100))")
                .font(.system(size: self.ringSize * 0.25, weight: .semibold, design: .rounded))
                .foregroundColor(.primary.opacity(0.7))
        }
        .frame(width: self.ringSize, height: self.ringSize)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                self.animatedProgress = self.progress
            }
        }
        .onChange(of: self.progress) { _, newProgress in
            withAnimation(.easeOut(duration: 0.4)) {
                self.animatedProgress = newProgress
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityDescription(for: self.progress))
    }

    // MARK: - Arc Segment

    private func arcSegment(
        progress: Double,
        startAngle: Double,
        color: Color
    ) -> some View {
        Circle()
            .trim(
                from: CGFloat(startAngle / 360.0),
                to: CGFloat(startAngle / 360.0 + (progress * 0.25))
            )
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: self.lineWidth,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(-90))
    }

    // MARK: - Colors

    static let reflectColor = Color.purple
    static let laserColor = Color.orange
    static let highlightColor = Color.teal
    static let energiseColor = Color.green

    // MARK: - Accessibility

    private static func accessibilityDescription(for progress: DayModuleProgress) -> String {
        let overall = Int(progress.overallProgress * 100)
        return "\(overall) percent complete. " +
            "Reflect \(Int(progress.reflectProgress * 100))%, " +
            "Laser \(Int(progress.laserProgress * 100))%, " +
            "Highlight \(Int(progress.highlightProgress * 100))%, " +
            "Energise \(Int(progress.energiseProgress * 100))%"
    }
}

// MARK: - Legend

/// Horizontal legend showing module names and colors.
struct DayRingLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            Self.legendDot(color: DayRingView.reflectColor, label: Strings.DayRing.reflect)
            Self.legendDot(color: DayRingView.laserColor, label: Strings.DayRing.laser)
            Self.legendDot(color: DayRingView.highlightColor, label: Strings.DayRing.highlight)
            Self.legendDot(color: DayRingView.energiseColor, label: Strings.DayRing.energise)
        }
    }

    private static func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
