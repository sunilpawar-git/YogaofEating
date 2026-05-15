import SwiftUI

/// A minimalist, tappable tag for displaying the meal type.
struct MealTypeTag: View {
    let mealType: MealType

    var body: some View {
        let color = self.mealType.displayColor
        HStack(spacing: 4) {
            Image(systemName: self.mealType.iconName)
                .font(FontTheme.textEntry(size: 10, weight: .semibold))
            Text(self.mealType.displayName)
                .font(FontTheme.textEntry(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.15)))
        .foregroundColor(color)
        .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 0.5))
        .mealPillShadow()
    }
}

#Preview {
    MealTypeTag(mealType: .dinner)
        .padding()
}
