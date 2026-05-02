import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var selectedTab = 1
    @State private var hasSetInitialTab = false

    /// Pure function: determines which tab to show on launch.
    /// Highlight before noon if sleep not logged, otherwise Energise.
    static func defaultTab(currentHour: Int, hasSleepLogged: Bool) -> Int {
        if currentHour < 12, !hasSleepLogged { return 0 }
        return 1
    }

    var body: some View {
        VStack(spacing: 0) {
            DateNavigationBanner(
                formattedDate: self.viewModel.formattedSelectedDate,
                isViewingToday: self.viewModel.isViewingToday,
                canNavigateToPreviousDay: self.viewModel.canNavigateToPreviousDay,
                canNavigateToNextDay: self.viewModel.canNavigateToNextDay,
                onPreviousDay: { self.viewModel.navigateToPreviousDay() },
                onNextDay: { self.viewModel.navigateToNextDay() },
                onNavigateToToday: { self.viewModel.navigateToToday() }
            )

            TabView(selection: self.$selectedTab) {
                HighlightView(
                    data: self.viewModel.highlightViewData,
                    onSleepQualityChanged: { self.viewModel.updateHighlightSleepQuality($0) },
                    onSleepNotesChanged: { self.viewModel.updateHighlightSleepNotes($0) },
                    onAddTodo: { self.viewModel.addHighlightTodo($0) },
                    onRemoveTodo: { self.viewModel.removeHighlightTodo($0) },
                    onMorningThoughtsChanged: { self.viewModel.updateHighlightMorningThoughts($0) }
                )
                .tabItem {
                    Label("Highlight", systemImage: "star.fill")
                }
                .tag(0)

                MainScreenView()
                    .tabItem {
                        Label("Energise", systemImage: "flame.fill")
                    }
                    .tag(1)

                ReflectView(
                    data: self.viewModel.reflectViewData,
                    onJournalTextChanged: { self.viewModel.updateReflectJournalText($0) },
                    onFeelingChanged: { self.viewModel.updateReflectFeeling($0) },
                    onTodoToggled: { self.viewModel.toggleTodoAccomplished($0) }
                )
                .tabItem {
                    Label("Reflect", systemImage: "moon.stars.fill")
                }
                .tag(2)
            }
        }
        .onAppear {
            guard !self.hasSetInitialTab else { return }
            self.hasSetInitialTab = true
            let hasSleep = self.viewModel.highlightViewData.sleepQuality != nil
            let hour = Calendar.current.component(.hour, from: Date())
            let target = Self.defaultTab(currentHour: hour, hasSleepLogged: hasSleep)
            // Suppress animation so there is no visible tab flash on first render.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                self.selectedTab = target
            }
        }
        .alert(
            Strings.Validation.errorTitle,
            isPresented: self.$viewModel.showValidationErrorAlert,
            presenting: self.viewModel.lastValidationError
        ) { _ in
            Button(Strings.Validation.dismissButton) {
                self.viewModel.showValidationErrorAlert = false
                self.viewModel.lastValidationError = nil
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(MainViewModel(skipDataLoading: true))
}
