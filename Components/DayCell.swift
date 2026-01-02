import SwiftUI

/// A single cell in the heatmap representing one day.
/// Colored based on the health score and smiley state of that day.
struct DayCell: View {
    let date: Date
    let snapshot: DailySmileySnapshot?

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(self.backgroundColor)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(
                        self.isToday ? Color.primary : Color.primary.opacity(0.1),
                        lineWidth: self.isToday ? 1.5 : 0.5
                    )
            )
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(self.isToday ? "heatmap-cell-today" : "heatmap-cell")
            .accessibilityLabel(self.accessibilityLabelText)
            .accessibilityAddTraits(.isButton)
            .help(self.accessibilityLabelText)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(self.date)
    }

    private var backgroundColor: Color {
        guard let snapshot = self.snapshot else {
            return Color.primary.opacity(0.05) // Empty day
        }

        if snapshot.isEmpty {
            return Color.primary.opacity(0.05)
        }

        // Intensity based on health score (0.0 to 1.0)
        let score = snapshot.averageHealthScore

        // Mood-based coloring
        switch snapshot.smileyState.mood {
        case .serene:
            return Color.green.opacity(0.2 + (score * 0.6))
        case .neutral:
            return Color.blue.opacity(0.2 + (score * 0.6))
        case .overwhelmed:
            return Color.orange.opacity(0.2 + (score * 0.6))
        }
    }

    private var accessibilityLabelText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: self.date)

        if let snapshot = self.snapshot, !snapshot.isEmpty {
            return "\(dateString): \(snapshot.mealCount) meals, score \(Int(snapshot.averageHealthScore * 100))%"
        } else {
            return "\(dateString): No data"
        }
    }
}

#Preview {
    HStack {
        DayCell(date: Date(), snapshot: nil)
            .frame(width: 20)
        DayCell(
            date: Date(),
            snapshot: DailySmileySnapshot(
                id: UUID(),
                date: Date(),
                smileyState: SmileyState(scale: 1.0, mood: .serene),
                meals: [Meal(id: UUID(), timestamp: Date(), mealType: .lunch, items: ["Salad"], healthScore: 0.9)],
                mealCount: 1,
                averageHealthScore: 0.9
            )
        )
        .frame(width: 20)
    }
    .padding()
}
