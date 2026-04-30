import SwiftUI

// MARK: - MainScreenView Sheet Modifier

/// A `ViewModifier` that attaches modal sheets for `MainScreenView`.
/// Only settings and insight sheets remain — reflection sheets moved to Highlight/Reflect tabs.
private struct MainScreenSheetsModifier: ViewModifier {
    @ObservedObject var viewModel: MainViewModel
    @Binding var showingSettings: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: self.$showingSettings) {
                SettingsView(mainViewModel: self.viewModel)
            }
            .sheet(isPresented: self.$viewModel.showInsightSheet) {
                if let insight = self.viewModel.currentInsight {
                    InsightBottomSheet(
                        insight: insight,
                        onDismiss: {
                            self.viewModel.dismissInsight()
                        }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                } else {
                    Color.clear
                        .onAppear { self.viewModel.showInsightSheet = false }
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Attaches `MainScreenView` modal sheets in one call.
    func mainScreenSheets(viewModel: MainViewModel, showingSettings: Binding<Bool>) -> some View {
        self.modifier(MainScreenSheetsModifier(viewModel: viewModel, showingSettings: showingSettings))
    }
}
