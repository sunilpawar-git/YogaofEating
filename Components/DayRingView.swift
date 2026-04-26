import SwiftUI

/// Compact 4-segment circular progress ring showing daily module completion.
/// Uses shared RingArcSegment for arc drawing (same as HeroRingView).
struct DayRingView: View {
    let progress: DayModuleProgress
    var ringSize: CGFloat = AppTheme.HeroRing.headerSize
    var lineWidth: CGFloat = AppTheme.HeroRing.headerLineWidth

    @State private var animatedProgress = DayModuleProgress.empty

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: self.lineWidth)

            ForEach(DayModule.allCases) { module in
                RingArcSegment(
                    progress: self.moduleProgress(for: module),
                    startAngle: RingArcSegment.startAngles[module.rawValue],
                    color: module.color,
                    lineWidth: self.lineWidth
                )
            }

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
        .accessibilityLabel(HeroRingView.accessibilityDescription(for: self.progress))
    }

    private func moduleProgress(for module: DayModule) -> Double {
        switch module {
        case .reflect: self.animatedProgress.reflectProgress
        case .laser: self.animatedProgress.laserProgress
        case .highlight: self.animatedProgress.highlightProgress
        case .energise: self.animatedProgress.energiseProgress
        }
    }
}

// MARK: - Legend

/// Horizontal legend showing module names and colors.
struct DayRingLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(DayModule.allCases) { module in
                Self.legendDot(color: module.color, label: module.title)
            }
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
