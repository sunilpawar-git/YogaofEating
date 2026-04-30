import SwiftUI

struct HighlightView: View {
    let data: (smileyState: SmileyState, mealsCount: Int, averageScore: Double, sleepQuality: SleepQuality?)?

    var body: some View {
        ContentUnavailableView(
            "Highlights",
            systemImage: "star.fill",
            description: Text("Coming soon")
        )
    }
}

#Preview {
    HighlightView(
        data: (
            smileyState: SmileyState(scale: 1.0, mood: .serene),
            mealsCount: 3,
            averageScore: 0.75,
            sleepQuality: .good
        )
    )
}
