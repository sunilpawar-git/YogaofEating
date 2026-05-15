import SwiftUI

/// A minimalist, tappable tag for displaying the meal type.
struct MealTypeTag: View {
    let mealType: MealType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: self.mealType.iconName)
                .font(.system(size: 10, weight: .semibold))
            Text(self.mealType.displayName)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(self.mealType.displayColor.opacity(0.15))
        )
        .foregroundColor(self.mealType.displayColor)
        .overlay(
            Capsule()
                .stroke(self.mealType.displayColor.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(
            color: AppTheme.MealCard.pillShadowColor,
            radius: AppTheme.MealCard.pillShadowRadius,
            y: AppTheme.MealCard.pillShadowY
        )
    }
}

#Preview {
    MealTypeTag(mealType: .dinner)
        .padding()
}
