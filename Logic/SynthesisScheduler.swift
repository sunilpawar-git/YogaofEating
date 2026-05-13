import Foundation

// MARK: - SynthesisScheduling Protocol

@MainActor
protocol SynthesisScheduling: AnyObject {
    func schedule(_ trigger: SynthesisTrigger)
}

// MARK: - SynthesisScheduler

/// Debounced scheduler that re-synthesises wellbeing data whenever a meaningful
/// data change occurs across any of the six trigger points (meals, sleep, journal,
/// todos, feeling, morning thoughts).
///
/// Non-sleep triggers are collapsed via a configurable debounce window so that
/// rapid sequential changes (e.g. typing, toggling todos) produce a single
/// synthesis cycle. `.sleepLogged` bypasses the debounce and fires immediately —
/// sleep is a high-signal event that warrants an instant insight cycle.
///
/// ### Two-phase wiring with MainViewModel
/// `SynthesisScheduler()` may be created with no handler during Swift's two-phase
/// initialisation. Call `setHandler(_:)` in phase 2 (after all stored properties
/// are set) to wire the lifecycle callback.
@MainActor
final class SynthesisScheduler: SynthesisScheduling {
    // UInt64? lets the default value be nil (avoids accessing TimingConstants in a
    // nonisolated default-parameter expression; actual default is resolved in the body).
    private let debounceNanoseconds: UInt64
    private var handler: ((SynthesisTrigger) -> Void)?
    private var pendingTask: Task<Void, Never>?

    /// - Parameters:
    ///   - debounceNanoseconds: Collapse window for non-sleep triggers. Pass `nil` to
    ///     use `TimingConstants.synthesisDebounceNanoseconds`. Pass a smaller value in tests.
    ///   - handler: Called on MainActor with the winning trigger after debounce (or immediately
    ///     for `.sleepLogged`). May be `nil` when using two-phase init; set via `setHandler(_:)`.
    init(debounceNanoseconds: UInt64? = nil, handler: ((SynthesisTrigger) -> Void)? = nil) {
        self.debounceNanoseconds = debounceNanoseconds ?? TimingConstants.synthesisDebounceNanoseconds
        self.handler = handler
    }

    /// Wires the lifecycle callback after the owner is fully initialised.
    /// Called from `MainViewModel.init` phase 2 when no injected scheduler was provided.
    func setHandler(_ handler: @escaping (SynthesisTrigger) -> Void) {
        self.handler = handler
    }

    func schedule(_ trigger: SynthesisTrigger) {
        self.pendingTask?.cancel()

        if TimingConstants.sleepTriggerBypassesDebounce, trigger == .sleepLogged {
            // Bypass debounce — fire on next event-loop turn
            self.pendingTask = Task { [weak self] in
                guard let self, !Task.isCancelled else { return }
                self.handler?(trigger)
            }
            return
        }

        self.pendingTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: self.debounceNanoseconds)
            guard !Task.isCancelled else { return }
            self.handler?(trigger)
        }
    }
}
