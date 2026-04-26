import SwiftUI

/// Single-line insight/quote display at the bottom of the home screen.
/// Truncates long text, fades in, and supports tap to expand.
struct AIWhisperView: View {
    let text: String
    var onTap: (() -> Void)?

    @State private var appeared = false

    var body: some View {
        Button {
            self.onTap?()
        } label: {
            Text(self.truncatedText)
                .font(.caption)
                .foregroundColor(AppTheme.textMuted)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .opacity(self.appeared ? 1 : 0)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeIn(duration: 0.8).delay(0.3)) {
                self.appeared = true
            }
        }
        .accessibilityLabel(self.text)
    }

    private var truncatedText: String {
        if self.text.count <= 80 { return self.text }
        let prefix = self.text.prefix(77)
        return String(prefix) + "..."
    }
}
