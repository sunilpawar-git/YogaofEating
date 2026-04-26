import Combine
import Foundation

/// ViewModel for the radial home screen.
/// Computes active module, avatar state, and whisper text from MainViewModel data.
/// Always initialized with a concrete MainViewModel — no optional dependency, no deferred binding.
@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published State

    @Published var moduleOverride: DayModule?

    // MARK: - Dependencies

    private let mainViewModel: MainViewModel

    // MARK: - Initialization

    init(mainViewModel: MainViewModel) {
        self.mainViewModel = mainViewModel
    }

    // MARK: - Computed Properties

    var dayPhase: DayPhase { .now }

    var selectedModule: DayModule {
        ActiveModuleResolver.resolve(
            phase: self.dayPhase,
            hasIntention: self.mainViewModel.todaysIntention != nil,
            override: self.moduleOverride
        )
    }

    var avatarEmoji: String {
        let meals = self.mainViewModel.meals
        guard !meals.isEmpty else { return Strings.Home.avatarNeutral }

        let avgScore = meals.map(\.healthScore).reduce(0, +) / Double(meals.count)
        if avgScore >= 0.7 { return Strings.Home.avatarSerene }
        if avgScore < 0.4 { return Strings.Home.avatarOverwhelmed }
        return Strings.Home.avatarNeutral
    }

    var whisperText: String {
        if let insight = self.mainViewModel.currentInsight {
            return insight.insightText
        }
        return QuoteService.getDailyQuote().text
    }

    var moduleProgress: DayModuleProgress {
        guard let snapshot = self.mainViewModel.todaysSnapshot else {
            return .empty
        }
        return DayModuleProgress.compute(from: snapshot)
    }

    // MARK: - Actions

    func selectModule(_ module: DayModule) {
        self.moduleOverride = module
    }

    func resetToAutoModule() {
        self.moduleOverride = nil
    }
}
