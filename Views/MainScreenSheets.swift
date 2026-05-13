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
                    .environmentObject(AuthService.shared)
            }
            .sheet(isPresented: self.$viewModel.showInsightSheet) {
                if let insight = self.viewModel.currentInsight {
                    InsightBottomSheet(
                        insight: insight,
                        onDismiss: { self.viewModel.dismissInsight() }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                } else {
                    Color.clear
                        .onAppear { self.viewModel.showInsightSheet = false }
                }
            }
            .sheet(isPresented: self.$viewModel.showBreakdownSheet) {
                if let contract = self.viewModel.wellbeingBreakdownContract {
                    WellbeingBreakdownSheet(contract: contract, onDismiss: {
                        self.viewModel.showBreakdownSheet = false
                    })
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                } else {
                    Color.clear
                        .onAppear { self.viewModel.showBreakdownSheet = false }
                }
            }
            .sheet(isPresented: self.$viewModel.showBriefingSheet) {
                if let insight = self.viewModel.currentInsight {
                    BriefingDetailView(
                        insight: insight,
                        onDismiss: { self.viewModel.showBriefingSheet = false }
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                } else {
                    Color.clear
                        .onAppear { self.viewModel.showBriefingSheet = false }
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
