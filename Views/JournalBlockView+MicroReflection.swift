import SwiftUI

extension JournalBlockView {
    @ViewBuilder var microReflectionRow: some View {
        if !self.meal.items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                MicroReflectionRatingRow(
                    label: Strings.MicroReflection.hungerLabel,
                    value: self.meal.preHunger,
                    onChange: { newValue in
                        self.onMicroReflection?(
                            self.meal.id,
                            newValue,
                            self.meal.postSatisfaction
                        )
                    }
                )
                MicroReflectionRatingRow(
                    label: Strings.MicroReflection.satisfactionLabel,
                    value: self.meal.postSatisfaction,
                    onChange: { newValue in
                        self.onMicroReflection?(
                            self.meal.id,
                            self.meal.preHunger,
                            newValue
                        )
                    }
                )
            }
            .padding(.top, 4)
        }
    }
}

struct MicroReflectionRatingRow: View {
    let label: String
    let value: Int?
    let onChange: (Int) -> Void

    /// Number of rating steps (1–5). Used in UI loops and accessibility labels.
    private let maxRating = 5

    var body: some View {
        HStack(spacing: 6) {
            Text(self.label)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)

            ForEach(1...self.maxRating, id: \.self) { rating in
                Button {
                    self.onChange(rating)
                } label: {
                    Circle()
                        .fill(self.fillColor(for: rating))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.secondary.opacity(0.3),
                                    lineWidth: 0.5
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    "\(self.label) \(rating) of \(self.maxRating)"
                )
            }
        }
    }

    private func fillColor(for rating: Int) -> Color {
        guard let current = value, rating <= current else {
            return Color.secondary.opacity(0.1)
        }
        return AppTheme.streakAccent.opacity(
            0.3 + Double(rating) / Double(self.maxRating) * 0.5
        )
    }
}
