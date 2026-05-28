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
            .sheet(isPresented: self.$viewModel.showInsightPreparingSheet) {
                InsightPreparingSheet(contract: InsightPreparingSheetContract(
                    weekdayName: Self.currentWeekdayName(),
                    isGenerating: self.viewModel.isInsightGenerationInProgress,
                    mealCount: self.viewModel.meals.count,
                    averageScore: Self.averageScore(meals: self.viewModel.meals),
                    onRefresh: { self.viewModel.triggerInsightGeneration(force: true) },
                    onDismiss: { self.viewModel.showInsightPreparingSheet = false }
                ))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            // Placed on the parent modifier chain (not inside sheet content) so it fires
            // reliably even during sheet dismiss animation.
            .onChange(of: self.viewModel.currentInsight) { _, newInsight in
                self.viewModel.handleInsightGeneratedDuringFallback(newInsight)
            }
            .sheet(isPresented: Binding(
                get: { self.viewModel.showBriefingSheet && self.viewModel.currentInsight != nil },
                set: { self.viewModel.showBriefingSheet = $0 }
            )) {
                if let insight = self.viewModel.currentInsight {
                    BriefingDetailView(
                        insight: insight,
                        liveBreakdown: self.viewModel.wellbeingBreakdownContract,
                        isLikelyStale: self.viewModel.isBriefingLikelyStale,
                        onDismiss: { self.viewModel.showBriefingSheet = false },
                        onRefresh: {
                            self.viewModel.showBriefingSheet = false
                            self.viewModel.triggerInsightGeneration(force: true)
                        }
                    )
                    .onAppear { self.viewModel.markBriefingViewed() }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
    }

    // MARK: - Helpers

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    private static func currentWeekdayName() -> String {
        self.weekdayFormatter.string(from: Date())
    }

    private static func averageScore(meals: [Meal]) -> Double? {
        let scores = meals.map(\.healthScore)
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }
}

// MARK: - View Extension

extension View {
    /// Attaches `MainScreenView` modal sheets in one call.
    func mainScreenSheets(viewModel: MainViewModel, showingSettings: Binding<Bool>) -> some View {
        self.modifier(MainScreenSheetsModifier(viewModel: viewModel, showingSettings: showingSettings))
    }
}
