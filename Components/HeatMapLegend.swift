import SwiftUI

struct HeatMapLegend: View {
    private let cellSize: CGFloat = 14
    private let cornerRadius: CGFloat = 3

    private let baseOpacity: Double = 0.25
    private let opacityRange: Double = 0.6

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Legend")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            HStack(spacing: 20) {
                self.legendItem(title: "Serene", color: .green, identifier: "legend-serene")
                    .accessibilityLabel("Serene mood: green colors indicate calm, balanced eating")
                self.legendItem(title: "Neutral", color: .blue, identifier: "legend-neutral")
                    .accessibilityLabel("Neutral mood: blue colors indicate typical eating")
                self.legendItem(title: "Overwhelmed", color: .orange, identifier: "legend-overwhelmed")
                    .accessibilityLabel("Overwhelmed mood: orange colors indicate stress eating")
            }

            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: self.cornerRadius)
                    .fill(Color.primary.opacity(0.03))
                    .frame(width: self.cellSize, height: self.cellSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: self.cornerRadius)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func legendItem(title: String, color: Color, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                ForEach(0..<4) { idx in
                    let score = Double(idx) / 3.0
                    let opacity = self.baseOpacity + (score * self.opacityRange)
                    RoundedRectangle(cornerRadius: self.cornerRadius)
                        .fill(color.opacity(opacity))
                        .frame(width: self.cellSize, height: self.cellSize)
                        .overlay(
                            RoundedRectangle(cornerRadius: self.cornerRadius)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                }
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityIdentifier(identifier)
        }
    }
}
