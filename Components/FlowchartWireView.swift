import SwiftUI

/// A custom SwiftUI Shape that draws a comical, squiggly wire between two points.
struct FlowchartWire: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var amplitude: CGFloat = 10
    var frequency: CGFloat = 2
    var phase: CGFloat // For animation

    var animatableData: CGFloat {
        get { self.phase }
        set { self.phase = newValue }
    }

    func path(in _: CGRect) -> Path {
        var path = Path()
        path.move(to: self.startPoint)

        let diffX = self.endPoint.x - self.startPoint.x
        let diffY = self.endPoint.y - self.startPoint.y
        let length = sqrt(diffX * diffX + diffY * diffY)

        // Guard against zero length (points are the same) to avoid division by zero / NaN
        guard length > 0 else {
            return path
        }

        let unitX = -diffY / length
        let unitY = diffX / length

        let steps = 50
        for stepIndex in 0...steps {
            let progress = CGFloat(stepIndex) / CGFloat(steps)
            let basePointX = self.startPoint.x + diffX * progress
            let basePointY = self.startPoint.y + diffY * progress

            // Add squiggly offsets based on sine wave
            let sineOffset = sin(progress * .pi * 2 * self.frequency + self.phase) * self.amplitude

            let finalX = basePointX + unitX * sineOffset
            let finalY = basePointY + unitY * sineOffset

            path.addLine(to: CGPoint(x: finalX, y: finalY))
        }

        return path
    }
}

/// A view wrapper that animates the FlowchartWire.
struct FlowchartWireView: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    @State private var phase: CGFloat = 0

    var body: some View {
        FlowchartWire(startPoint: self.startPoint, endPoint: self.endPoint, phase: self.phase)
            .stroke(Color.primary.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    self.phase = .pi * 2
                }
            }
    }
}

#Preview {
    FlowchartWireView(startPoint: CGPoint(x: 50, y: 50), endPoint: CGPoint(x: 300, y: 300))
}
