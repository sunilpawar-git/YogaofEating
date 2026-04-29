import SwiftUI

/// A reusable date header with navigation controls for day-based navigation.
/// Shows an optional one-line contextual subtext below the date for added warmth.
struct DateHeaderNavigationView: View {
    // MARK: - Properties

    let formattedDate: String
    let isViewingToday: Bool
    let canNavigateToPreviousDay: Bool
    let onPreviousDay: () -> Void
    let onNavigateToToday: () -> Void

    /// Optional one-line context below the date (e.g. "Good morning", "Slept well").
    /// Computed by the ViewModel via DateContextProvider — nil renders nothing.
    let contextSubtext: String?

    init(
        formattedDate: String,
        isViewingToday: Bool,
        canNavigateToPreviousDay: Bool,
        onPreviousDay: @escaping () -> Void,
        onNavigateToToday: @escaping () -> Void,
        contextSubtext: String? = nil
    ) {
        self.formattedDate = formattedDate
        self.isViewingToday = isViewingToday
        self.canNavigateToPreviousDay = canNavigateToPreviousDay
        self.onPreviousDay = onPreviousDay
        self.onNavigateToToday = onNavigateToToday
        self.contextSubtext = contextSubtext
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 16) {
            self.previousDayButton
            self.dateDisplayStack
            self.trailingSpacerView
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Subviews

    private var previousDayButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.onPreviousDay()
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(self.canNavigateToPreviousDay ? .primary : .secondary.opacity(0.3))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .disabled(!self.canNavigateToPreviousDay)
        .accessibilityIdentifier("previous-day-button")
        .accessibilityLabel("Previous day")
    }

    private var dateDisplayStack: some View {
        VStack(spacing: 4) {
            Text(self.formattedDate)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .accessibilityIdentifier("date-header")

            if let subtext = self.contextSubtext {
                Text(subtext)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("date-context-subtext")
                    .transition(.opacity)
            }

            if !self.isViewingToday {
                self.backToTodayButton
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var backToTodayButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.onNavigateToToday()
            }
        } label: {
            HStack(spacing: 4) {
                Text("Back to Today")
                    .font(.caption)
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("today-button")
        .accessibilityLabel("Back to Today")
        .accessibilityHint("Return to today's view")
    }

    /// Spacer to balance the left arrow (right arrow removed - users navigate backward only)
    private var trailingSpacerView: some View {
        Color.clear
            .frame(width: 44, height: 44)
    }
}

#Preview("Viewing Today") {
    DateHeaderNavigationView(
        formattedDate: "Tuesday, 7 Jan 2026",
        isViewingToday: true,
        canNavigateToPreviousDay: true,
        onPreviousDay: {},
        onNavigateToToday: {}
    )
}

#Preview("Viewing Past Day") {
    DateHeaderNavigationView(
        formattedDate: "Monday, 6 Jan 2026",
        isViewingToday: false,
        canNavigateToPreviousDay: true,
        onPreviousDay: {},
        onNavigateToToday: {}
    )
}
