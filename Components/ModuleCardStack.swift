import SwiftUI

/// Horizontal pager showing module cards with custom page indicator.
/// Uses ScrollView + scrollTargetLayout (iOS 17+) for full visual control.
struct ModuleCardStack: View {
    @Binding var selectedModule: DayModule
    let dataSource: ModuleCardDataSource

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            self.cardPager
            ModulePageIndicator(selectedModule: self.selectedModule)
        }
    }

    private var cardPager: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: AppTheme.Spacing.medium) {
                ForEach(DayModule.allCases) { module in
                    ModuleCardView(module: module) {
                        self.cardContent(for: module)
                    }
                    .containerRelativeFrame(.horizontal)
                    .id(module)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: Binding(
            get: { Optional(self.selectedModule) },
            set: { newValue in
                if let module = newValue {
                    self.selectedModule = module
                }
            }
        ))
    }

    @ViewBuilder
    private func cardContent(for module: DayModule) -> some View {
        switch module {
        case .reflect:
            ReflectCardBody(dataSource: self.dataSource)
        case .energise:
            EnergiseCardBody(dataSource: self.dataSource)
        case .laser:
            LaserCardBody(dataSource: self.dataSource)
        case .highlight:
            HighlightCardBody(dataSource: self.dataSource)
        }
    }
}
