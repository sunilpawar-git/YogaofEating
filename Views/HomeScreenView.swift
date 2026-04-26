import SwiftUI

/// Radial home screen composing HeroRingView, ModuleCardStack, and AIWhisperView.
/// HomeViewModel is created at @StateObject init time with the live MainViewModel,
/// guaranteeing all computed properties are correct on the very first render.
/// Delegates all sheet presentations to MainScreenView's existing sheet modifiers.
struct HomeScreenView: View {
    @EnvironmentObject private var mainViewModel: MainViewModel
    @StateObject private var homeViewModel: HomeViewModel

    init(mainViewModel: MainViewModel) {
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(mainViewModel: mainViewModel))
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer(minLength: AppTheme.Spacing.medium)
            self.heroRing
            self.cardStack
            self.whisper
            Spacer(minLength: AppTheme.Spacing.small)
        }
    }
}

// MARK: - Subviews

private extension HomeScreenView {
    var heroRing: some View {
        HeroRingView(
            progress: self.homeViewModel.moduleProgress,
            avatarText: self.homeViewModel.avatarEmoji,
            activeModule: self.homeViewModel.selectedModule,
            onSegmentTap: { module in
                self.homeViewModel.selectModule(module)
            }
        )
    }

    var cardStack: some View {
        ModuleCardStack(
            selectedModule: Binding(
                get: { self.homeViewModel.selectedModule },
                set: { self.homeViewModel.selectModule($0) }
            ),
            dataSource: self.mainViewModel
        )
        .frame(height: AppTheme.HeroRing.cardStackHeight)
    }

    var whisper: some View {
        AIWhisperView(
            text: self.homeViewModel.whisperText,
            onTap: {
                if self.mainViewModel.currentInsight != nil {
                    self.mainViewModel.showInsightSheet = true
                }
            }
        )
    }
}
