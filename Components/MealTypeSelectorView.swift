import SwiftUI

/// Horizontal scrollable meal type selector with beautiful pill design
struct MealTypeSelectorView: View {
    @Binding var selectedType: MealType
    let onSelect: (MealType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    MealTypePill(
                        mealType: mealType,
                        isSelected: self.selectedType == mealType,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                self.selectedType = mealType
                            }
                            self.onSelect(mealType)
                            // Haptic feedback
                            SensoryService.shared.playNudge(style: .medium)
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

/// Individual meal type pill button
private struct MealTypePill: View {
    let mealType: MealType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: self.onTap) {
            HStack(spacing: 6) {
                Image(systemName: self.iconName)
                    .font(.system(size: 14, weight: .semibold))

                Text(self.mealType.displayName)
                    .font(.system(size: 14, weight: self.isSelected ? .bold : .medium, design: .rounded))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if self.isSelected {
                    // Active state: gradient fill
                    LinearGradient(
                        colors: self.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(Capsule())
                    .shadow(color: self.gradientColors.first?.opacity(0.3) ?? .clear, radius: 8, y: 4)
                } else {
                    // Inactive state: border only
                    Capsule()
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1.5)
                        .background(
                            Capsule()
                                .fill(Color.primary.opacity(0.05))
                        )
                }
            }
            .scaleEffect(self.isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // SF Symbol icon for each meal type
    private var iconName: String {
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

    // Gradient colors for each meal type
    private var gradientColors: [Color] {
        switch self.mealType {
        case .breakfast:
            [Color.orange, Color.yellow]
        case .lunch:
            [Color.green, Color.mint]
        case .dinner:
            [Color.purple, Color.indigo]
        case .snacks:
            [Color.pink, Color.orange]
        case .drinks:
            [Color.cyan, Color.blue]
        }
    }
}

#Preview {
    VStack {
        MealTypeSelectorView(
            selectedType: .constant(.lunch),
            onSelect: { _ in }
        )
        .padding()

        Spacer()
    }
}
