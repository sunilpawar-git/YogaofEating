import SwiftUI

struct StreakPillView: View {
    let streak: ConsistencyStreak

    @State private var showPopover = false

    var body: some View {
        Button {
            self.showPopover = true
        } label: {
            HStack(spacing: 4) {
                Text(Strings.Streak.flameEmoji)
                    .font(.caption)
                Text(Strings.Streak.pill(self.streak.current))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.streakAccent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(AppTheme.streakAccent.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Strings.Streak.pill(self.streak.current))
        .popover(isPresented: self.$showPopover) {
            VStack(spacing: 8) {
                Text(Strings.Streak.streakPopoverTitle)
                    .font(.headline)
                HStack {
                    Text(Strings.Streak.bestRecord)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(self.streak.best)")
                        .fontWeight(.bold)
                }
            }
            .padding()
            .frame(width: 180)
            .presentationCompactAdaptation(.popover)
        }
    }
}
