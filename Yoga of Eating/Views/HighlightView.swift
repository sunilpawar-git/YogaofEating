import SwiftUI

struct HighlightView: View {
    var body: some View {
        ContentUnavailableView(
            "Highlights",
            systemImage: "star.fill",
            description: Text("Coming soon")
        )
    }
}

#Preview {
    HighlightView()
}
