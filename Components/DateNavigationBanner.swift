import SwiftUI

/// Shared date navigation banner displayed above all tabs in RootTabView.
/// Shows left/right arrows for day navigation with date text centered.
/// All tabs sync to the same selected date through this single control.
struct DateNavigationBanner: View {
    let formattedDate: String
    let isViewingToday: Bool
    let canNavigateToPreviousDay: Bool
    let canNavigateToNextDay: Bool
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onNavigateToToday: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                self.leftArrow
                Spacer()
                self.dateDisplay
                Spacer()
                self.rightArrow
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            Divider()
                .opacity(0.3)
        }
        .background(Color(.systemBackground).opacity(0.95))
    }

    // MARK: - Subviews

    private var leftArrow: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.onPreviousDay()
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(self.canNavigateToPreviousDay ? .primary : .secondary.opacity(0.2))
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .disabled(!self.canNavigateToPreviousDay)
        .accessibilityIdentifier("date-previous-button")
        .accessibilityLabel("Previous day")
    }

    private var rightArrow: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.onNextDay()
            }
        } label: {
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(self.canNavigateToNextDay ? .primary : .secondary.opacity(0.2))
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .disabled(!self.canNavigateToNextDay)
        .accessibilityIdentifier("date-next-button")
        .accessibilityLabel("Next day")
    }

    private var dateDisplay: some View {
        VStack(spacing: 2) {
            Text(self.formattedDate)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)

            if !self.isViewingToday {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.onNavigateToToday()
                    }
                } label: {
                    Text("Back to today")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("date-today-button")
            }
        }
        .accessibilityIdentifier("date-banner-label")
    }
}

#Preview("Viewing Today") {
    DateNavigationBanner(
        formattedDate: "Wed, 30 Apr 2026",
        isViewingToday: true,
        canNavigateToPreviousDay: true,
        canNavigateToNextDay: false,
        onPreviousDay: {},
        onNextDay: {},
        onNavigateToToday: {}
    )
}

#Preview("Viewing Past Day") {
    DateNavigationBanner(
        formattedDate: "Tue, 29 Apr 2026",
        isViewingToday: false,
        canNavigateToPreviousDay: true,
        canNavigateToNextDay: true,
        onPreviousDay: {},
        onNextDay: {},
        onNavigateToToday: {}
    )
}
