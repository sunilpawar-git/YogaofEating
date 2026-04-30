import SwiftUI

struct ReflectView: View {
    let data: (mealsCount: Int, averageScore: Double)?

    var body: some View {
        ContentUnavailableView(
            "Reflect",
            systemImage: "moon.stars.fill",
            description: Text("Coming soon")
        )
    }
}

#Preview {
    ReflectView(
        data: (mealsCount: 3, averageScore: 0.72)
    )
}
