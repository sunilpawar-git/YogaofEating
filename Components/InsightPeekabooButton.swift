import SwiftUI

/// A floating "peekaboo" star button that reveals insights when tapped.
/// Appears at the bottom of the screen with a subtle animation.
struct InsightPeekabooButton: View {
    // MARK: - Properties

    /// Whether there's an unread insight (shows badge)
    let hasUnreadInsight: Bool

    /// Action when button is tapped
    let onTap: () -> Void

    // MARK: - State

    @State private var isPulsing = false
    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        Button(action: {
            SensoryService.shared.playNudge(style: .medium)
            self.onTap()
        }) {
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.yellow.opacity(0.3),
                                Color.orange.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(self.isPulsing ? 1.2 : 1.0)
                    .opacity(self.hasUnreadInsight ? 1.0 : 0.5)

                // Star emoji
                Text("⭐")
                    .font(.system(size: 32))
                    .scaleEffect(self.isPressed ? 0.9 : 1.0)

                // Unread badge
                if self.hasUnreadInsight {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .offset(x: 14, y: -14)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(self.isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: self.isPressed)
        .onAppear {
            if self.hasUnreadInsight {
                self.startPulseAnimation()
            }
        }
        .onChange(of: self.hasUnreadInsight) { _, newValue in
            if newValue {
                self.startPulseAnimation()
            } else {
                self.isPulsing = false
            }
        }
        .accessibilityLabel(Strings.Insight.dailyTitle)
        .accessibilityHint(self.hasUnreadInsight ? "New insight available" : "View your insight")
    }

    // MARK: - Private

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
        ) {
            self.isPulsing = true
        }
    }
}

// MARK: - Preview

#if DEBUG
    #Preview("With Unread") {
        VStack {
            Spacer()
            InsightPeekabooButton(hasUnreadInsight: true) {
                print("Tapped")
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }

    #Preview("Read") {
        VStack {
            Spacer()
            InsightPeekabooButton(hasUnreadInsight: false) {
                print("Tapped")
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }
#endif
