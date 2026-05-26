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
                    .environmentObject(self.viewModel)
                    .environmentObject(AuthService.shared)
            }
            .sheet(isPresented: Binding(
                get: { self.viewModel.showInsightSheet && self.viewModel.currentInsight != nil },
                set: { self.viewModel.showInsightSheet = $0 }
            )) {
                if let insight = self.viewModel.currentInsight {
                    InsightBottomSheet(
                        insight: insight,
                        onDismiss: { self.viewModel.dismissInsight() }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: Binding(
                get: { self.viewModel.showBreakdownSheet && self.viewModel.wellbeingBreakdownContract != nil },
                set: { self.viewModel.showBreakdownSheet = $0 }
            )) {
                if let contract = self.viewModel.wellbeingBreakdownContract {
                    WellbeingBreakdownSheet(contract: contract, onDismiss: {
                        self.viewModel.showBreakdownSheet = false
                    })
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: Binding(
                get: { self.viewModel.showBriefingSheet && self.viewModel.currentInsight != nil },
                set: { self.viewModel.showBriefingSheet = $0 }
            )) {
                if let insight = self.viewModel.currentInsight {
                    BriefingDetailView(
                        insight: insight,
                        onDismiss: { self.viewModel.showBriefingSheet = false },
                        onRefresh: {
                            self.viewModel.showBriefingSheet = false
                            self.viewModel.triggerInsightGeneration(force: true)
                        }
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
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
