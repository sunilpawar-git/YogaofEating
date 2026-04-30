import SwiftUI

// MARK: - MainScreenView Sheet Modifier

/// A `ViewModifier` that attaches all modal sheets for `MainScreenView`.
/// Extracted to keep `MainScreenView` under 300 lines.
private struct MainScreenSheetsModifier: ViewModifier {
    @ObservedObject var viewModel: MainViewModel
    @Binding var showingSettings: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: self.$showingSettings) {
                SettingsView(mainViewModel: self.viewModel)
            }
            // Note: Legacy showReflectionSheet removed - now using user-initiated sheets
            .sheet(isPresented: self.$viewModel.showSleepQualitySheet) {
                SleepQualityInputView(
                    onSelect: { quality in
                        self.viewModel.completeSleepQualityInput(quality)
                    },
                    onDismiss: {
                        self.viewModel.dismissSleepQualityInput()
                    },
                    suggestedQuality: self.viewModel.suggestedSleepQuality,
                    sleepData: self.viewModel.appleSleepData
                )
                .presentationDetents([.height(AppTheme.Layout.inputSheetHeight)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: self.$viewModel.showOverallFeelingSheet) {
                OverallFeelingInputView(
                    onSelect: { feeling in
                        self.viewModel.completeOverallFeelingInput(feeling)
                    },
                    onDismiss: {
                        self.viewModel.dismissOverallFeelingInput()
                    }
                )
                .presentationDetents([.height(AppTheme.Layout.feelingSheetHeight)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: self.$viewModel.showMorningMindCheckSheet) {
                MindCheckInputView(
                    existingEntries: self.viewModel.editingMorningEntries,
                    onSave: { entries in
                        self.viewModel.completeMorningMindCheckInput(entries)
                    },
                    onDismiss: {
                        self.viewModel.dismissMorningMindCheckInput()
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: self.$viewModel.showEveningMindCheckSheet) {
                EveningReviewView(
                    morningEntries: self.viewModel.todaysMorningMindCheck ?? [],
                    existingEveningEntries: self.viewModel.todaysEveningMindCheck,
                    showFeelingSelection: self.viewModel.isEndOfDayFlow,
                    onSave: { updatedMorning, evening, feeling in
                        self.viewModel.completeEveningReview(
                            updatedMorningEntries: updatedMorning,
                            eveningEntries: evening,
                            feeling: feeling
                        )
                    },
                    onDismiss: {
                        self.viewModel.dismissEveningMindCheckInput()
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: self.$viewModel.showInsightSheet) {
                // Guard: only show InsightBottomSheet when insight is available.
                // Defensive fallback prevents a blank sheet if sheet binding is triggered
                // before currentInsight is populated (e.g. race from external callers).
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
                    // Dismiss automatically when no insight available
                    Color.clear
                        .onAppear { self.viewModel.showInsightSheet = false }
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Attaches all `MainScreenView` modal sheets in one call.
    func mainScreenSheets(viewModel: MainViewModel, showingSettings: Binding<Bool>) -> some View {
        self.modifier(MainScreenSheetsModifier(viewModel: viewModel, showingSettings: showingSettings))
    }
}
