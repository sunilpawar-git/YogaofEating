import SwiftUI

/// Inline mid-day focus check: 3 quick buttons (scattered / okay / locked-in).
/// Appears in the timeline after 2+ meals if focusRating is nil.
struct FocusCheckView: View {
    let onRate: (Int) -> Void

    @State private var hasAnimated = false

    var body: some View {
        VStack(spacing: 10) {
            Text(Strings.Focus.promptTitle)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                self.focusButton(
                    rating: 1,
                    label: Strings.Focus.scattered,
                    icon: Strings.Focus.scatteredIcon,
                    tint: .orange
                )
                self.focusButton(
                    rating: 2,
                    label: Strings.Focus.okay,
                    icon: Strings.Focus.okayIcon,
                    tint: .blue
                )
                self.focusButton(
                    rating: 3,
                    label: Strings.Focus.lockedIn,
                    icon: Strings.Focus.lockedInIcon,
                    tint: .green
                )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .opacity(self.hasAnimated ? 1 : 0)
        .offset(y: self.hasAnimated ? 0 : 8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                self.hasAnimated = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Strings.Focus.promptTitle)
    }

    // MARK: - Private

    private func focusButton(
        rating: Int,
        label: String,
        icon: String,
        tint: Color
    ) -> some View {
        Button {
            self.onRate(rating)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(tint)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(tint.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint("Rate focus as \(label)")
    }
}
