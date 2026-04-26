import SwiftUI

/// Shared arc segment shape used by both DayRingView (44px) and HeroRingView (160px).
/// Draws a single colored arc within a quarter of the ring.
struct RingArcSegment: View {
    let progress: Double
    let startAngle: Double
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        Circle()
            .trim(
                from: CGFloat(self.startAngle / 360.0),
                to: CGFloat(self.startAngle / 360.0 + (self.progress * 0.25))
            )
            .stroke(
                self.color,
                style: StrokeStyle(
                    lineWidth: self.lineWidth,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(-90))
    }

    /// Canonical start angles for the four module quadrants.
    static let startAngles: [Double] = [0, 90, 180, 270]
}
