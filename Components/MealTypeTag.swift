import SwiftUI

/// A minimalist, tappable tag for displaying the meal type.
struct MealTypeTag: View {
    let mealType: MealType
    let isSelected: Bool

    // Minimalist pastel colors
    private var typeColor: Color {
        switch self.mealType {
        case .breakfast:
            .orange
        case .lunch:
            .green
        case .dinner:
            .purple
        case .snacks:
            .pink
        case .drinks:
            .blue
        }
    }

    private var icon: String {
        switch self.mealType {
        case .breakfast:
            "sunrise.fill"
        case .lunch:
            "fork.knife"
        case .dinner:
            "moon.stars.fill"
        case .snacks:
            "popcorn.fill"
        case .drinks:
            "cup.and.saucer.fill"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: self.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(self.mealType.displayName)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(self.typeColor.opacity(0.15))
        )
        .foregroundColor(self.typeColor)
        .overlay(
            Capsule()
                .stroke(self.typeColor.opacity(0.3), lineWidth: 0.5)
        )
    }
}

#Preview {
    MealTypeTag(mealType: .dinner, isSelected: true)
        .padding()
}
