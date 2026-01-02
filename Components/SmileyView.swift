import SwiftUI

/// A native SwiftUI view that renders a ubiquitous iOS emoji based on SmileyState.
struct SmileyView: View {
    let state: SmileyState

    var body: some View {
        Text(self.emojiForMood(self.state.mood))
            .font(.system(size: 80)) // Large base size for the emoji
            .scaleEffect(self.state.scale)
            .animation(.easeInOut(duration: 0.5), value: self.state.scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
