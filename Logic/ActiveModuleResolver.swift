import Foundation

/// Pure-function resolver that determines which module card should be
/// auto-selected on the home screen based on time of day and user state.
/// Override always takes precedence over automatic resolution.
enum ActiveModuleResolver {
    /// Resolves the active module for the home screen.
    /// - Parameters:
    ///   - phase: Current time-of-day phase
    ///   - hasIntention: Whether the user has set a daily intention
    ///   - override: User-selected module override (always wins if set)
    /// - Returns: The module to display as active
    static func resolve(
        phase: DayPhase,
        hasIntention: Bool,
        override: DayModule?
    ) -> DayModule {
        if let override { return override }

        switch phase {
        case .morning:
            return hasIntention ? .energise : .reflect
        case .midday:
            return .energise
        case .evening:
            return .highlight
        }
    }
}
