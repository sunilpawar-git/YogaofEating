import SwiftUI

struct ReflectView: View {
    var body: some View {
        ContentUnavailableView(
            "Reflect",
            systemImage: "moon.stars.fill",
            description: Text("Coming soon")
        )
    }
}

#Preview {
    ReflectView()
}
