import Foundation

/// Provides daily energy-expenditure data from a health sensor or other source.
///
/// Conforming types can be real HealthKit queries or test doubles.
/// Inject via `MainViewModel(activityProvider:)` — never create inside the ViewModel.
protocol ActivityDataProvider {
    /// Returns total active (exercise) calories burned for the given calendar day,
    /// or `nil` when data is unavailable or permission is denied.
    func fetchActiveCaloriesBurned(for date: Date) async -> Double?

    /// Returns total basal (resting) calories burned for the given calendar day,
    /// or `nil` when data is unavailable or permission is denied.
    func fetchBasalCaloriesBurned(for date: Date) async -> Double?
}
