import SwiftUI

/// A custom SwiftUI Shape that draws a comical, squiggly wire between two points.
struct FlowchartWire: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var amplitude: CGFloat = 10
    var frequency: CGFloat = 2
    var phase: CGFloat // For animation
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: startPoint)
        
        let steps = 50
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let x = startPoint.x + (endPoint.x - startPoint.x) * t
            let y = startPoint.y + (endPoint.y - startPoint.y) * t
            
            // Add squiggly offsets based on sine wave
            let sineOffset = sin(t * pi * 2 * frequency + phase) * amplitude
            
            // Perpendicular offset for organic feel
            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y
            let len = sqrt(dx*dx + dy*dy)
            let ux = -dy / len
            let uy = dx / len
            
            let finalX = x + ux * sineOffset
            let finalY = y + uy * sineOffset
            
            path.addLine(to: CGPoint(x: finalX, y: finalY))
        }
        
        return path
    }
    
    private let pi = CGFloat.pi
}

/// A view wrapper that animates the FlowchartWire.
struct FlowchartWireView: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    @State private var phase: CGFloat = 0
    
    var body: some View {
        FlowchartWire(startPoint: startPoint, endPoint: endPoint, phase: phase)
            .stroke(Color.primary.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = .pi * 2
                }
            }
    }
}

#Preview {
    FlowchartWireView(startPoint: CGPoint(x: 50, y: 50), endPoint: CGPoint(x: 300, y: 300))
}
