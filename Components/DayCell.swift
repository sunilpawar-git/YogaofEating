import SwiftUI

/// A single cell in the heatmap representing one day.
/// Colored based on the health score and smiley state of that day.
struct DayCell: View {
    let date: Date
    let snapshot: DailySmileySnapshot?

    /// The size of the cell. Defaults to 16pt for backwards compatibility.
    var cellSize: CGFloat = 16

    /// The corner radius of the cell. Defaults to 3pt for backwards compatibility.
    var cornerRadius: CGFloat = 3

    var body: some View {
        RoundedRectangle(cornerRadius: self.cornerRadius)
            .fill(self.backgroundColor)
            .frame(width: self.cellSize, height: self.cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: self.cornerRadius)
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
        guard let snapshot else {
            return Color.primary.opacity(0.05) // Empty day
        }

        if snapshot.isEmpty {
            return Color.primary.opacity(0.05)
        }

        // Intensity based on health score (0.0 to 1.0)
        // Clamp score to valid range to prevent invalid opacity values
        let rawScore = snapshot.averageHealthScore
        let score = rawScore.isFinite ? min(1.0, max(0.0, rawScore)) : 0.5

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

        if let snapshot, !snapshot.isEmpty {
            return "\(dateString): \(snapshot.mealCount) meals, score \(Int(snapshot.averageHealthScore * 100))%"
        } else {
            return "\(dateString): No data"
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        // Small cell (legacy size)
        DayCell(date: Date(), snapshot: nil, cellSize: 16, cornerRadius: 3)

        // Medium cell (new default)
        DayCell(date: Date(), snapshot: nil, cellSize: 32, cornerRadius: 4)

        // Large cell with data
        DayCell(
            date: Date(),
            snapshot: DailySmileySnapshot(
                id: UUID(),
                date: Date(),
                smileyState: SmileyState(scale: 1.0, mood: .serene),
                meals: [Meal(id: UUID(), timestamp: Date(), mealType: .lunch, items: ["Salad"], healthScore: 0.9)],
                mealCount: 1,
                averageHealthScore: 0.9
            ),
            cellSize: 40,
            cornerRadius: 5
        )
    }
    .padding()
}
