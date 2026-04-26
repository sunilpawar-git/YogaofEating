import SwiftUI

/// Generic card container for module content on the home screen.
/// Provides a rounded rectangle with a colored accent stripe at top,
/// module title, and a content slot.
struct ModuleCardView<Content: View>: View {
    let module: DayModule
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            self.accentStripe
            self.headerRow
            self.content()
            Spacer(minLength: 0)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(color: AppTheme.Shadow.subtle, radius: 4, x: 0, y: 2)
    }

    private var accentStripe: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(self.module.color)
            .frame(height: 4)
    }

    private var headerRow: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: self.module.icon)
                .foregroundColor(self.module.color)
                .font(.body)
            Text(self.module.title)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}
