import SwiftUI

/// Custom page indicator with module-colored dots.
/// Active dot is larger and uses the module's color; others are muted.
struct ModulePageIndicator: View {
    let selectedModule: DayModule

    var body: some View {
        HStack(spacing: 8) {
            ForEach(DayModule.allCases) { module in
                Circle()
                    .fill(self.dotColor(for: module))
                    .frame(
                        width: module == self.selectedModule ? 10 : 6,
                        height: module == self.selectedModule ? 10 : 6
                    )
                    .animation(.easeInOut(duration: 0.2), value: self.selectedModule)
            }
        }
    }

    private func dotColor(for module: DayModule) -> Color {
        module == self.selectedModule
            ? module.color
            : module.color.opacity(0.3)
    }
}
