import Foundation

/// Minimal data context passed to CausalNarrativeResolver for the physical dimension.
/// Uses only aggregate values (count, avg score) — never raw meal item text.
struct NarrativeContext: Equatable {
    let mealCount: Int
    let avgMealScore: Double
}
