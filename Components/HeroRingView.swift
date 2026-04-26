import SwiftUI

/// Large circular progress ring for the radial home screen.
/// Displays 4 module arcs, a center emoji avatar, and overall percentage.
/// Configurable size for reuse at both hero (160px) and compact scales.
struct HeroRingView: View {
    let progress: DayModuleProgress
    let avatarText: String
    var ringSize: CGFloat = AppTheme.HeroRing.heroSize
    var lineWidth: CGFloat = AppTheme.HeroRing.heroLineWidth
    var activeModule: DayModule?
    var onSegmentTap: ((DayModule) -> Void)?

    @State private var animatedProgress = DayModuleProgress.empty

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: self.lineWidth)

            self.moduleArcs
            self.centerContent
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
}

// MARK: - Subviews

private extension HeroRingView {
    var moduleArcs: some View {
        ForEach(DayModule.allCases) { module in
            let segmentWidth = (module == self.activeModule)
                ? self.lineWidth * 1.4
                : self.lineWidth
            RingArcSegment(
                progress: self.segmentProgress(for: module),
                startAngle: RingArcSegment.startAngles[module.rawValue],
                color: module.color,
                lineWidth: segmentWidth
            )
            .onTapGesture { self.onSegmentTap?(module) }
        }
    }

    var centerContent: some View {
        VStack(spacing: 2) {
            Text(self.avatarText)
                .font(.system(size: self.ringSize * AppTheme.HeroRing.centerFontRatio))
            Text("\(Int(self.animatedProgress.overallProgress * 100))%")
                .font(.system(
                    size: self.ringSize * 0.12,
                    weight: .semibold,
                    design: .rounded
                ))
                .foregroundColor(.primary.opacity(0.7))
        }
    }

    func segmentProgress(for module: DayModule) -> Double {
        switch module {
        case .reflect: self.animatedProgress.reflectProgress
        case .laser: self.animatedProgress.laserProgress
        case .highlight: self.animatedProgress.highlightProgress
        case .energise: self.animatedProgress.energiseProgress
        }
    }
}

// MARK: - Static Helpers

extension HeroRingView {
    static func avatarEmoji(for progress: DayModuleProgress) -> String {
        let overall = progress.overallProgress
        if overall >= 0.7 { return Strings.Home.avatarSerene }
        if overall > 0, overall < 0.15 { return Strings.Home.avatarOverwhelmed }
        return Strings.Home.avatarNeutral
    }

    static func accessibilityDescription(for progress: DayModuleProgress) -> String {
        let overall = Int(progress.overallProgress * 100)
        return "\(overall) percent complete. " +
            "Reflect \(Int(progress.reflectProgress * 100))%, " +
            "Laser \(Int(progress.laserProgress * 100))%, " +
            "Highlight \(Int(progress.highlightProgress * 100))%, " +
            "Energise \(Int(progress.energiseProgress * 100))%"
    }
}
