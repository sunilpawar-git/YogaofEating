import SwiftUI

/// A native SwiftUI view that renders a ubiquitous iOS emoji based on SmileyState.
struct SmileyView: View {
    let state: SmileyState

    var body: some View {
        Text(self.emojiForMood(self.state.mood))
            .font(.system(size: 80)) // Large base size for the emoji
            .scaleEffect(self.safeScale)
            .animation(.easeInOut(duration: 0.5), value: self.safeScale)
            // Ensure the view always has valid dimensions
            .frame(minWidth: 1, minHeight: 1)
    }

    /// Ensures scale is always a valid, positive, finite value within reasonable bounds
    private var safeScale: CGFloat {
        let scale = self.state.scale
        // Guard against NaN, infinity, zero, or negative values
        guard scale.isFinite, scale > 0 else {
            return 1.0
        }
        // Clamp to reasonable bounds to prevent layout issues
        return min(max(scale, 0.1), 10.0)
    }

    private func emojiForMood(_ mood: SmileyMood) -> String {
        switch mood {
        case .serene:
            "🙂"
        case .neutral:
            "😐"
        case .overwhelmed:
            "😮"
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        SmileyView(state: SmileyState(scale: 1.0, mood: .serene))
            .frame(width: 140, height: 140)
        SmileyView(state: SmileyState(scale: 1.0, mood: .neutral))
            .frame(width: 140, height: 140)
        SmileyView(state: SmileyState(scale: 1.0, mood: .overwhelmed))
            .frame(width: 140, height: 140)
    }
}
