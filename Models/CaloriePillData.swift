import Foundation
import SwiftUI

// MARK: - CaloriePillData

/// Immutable data contract for the CaloriePillView.
/// Encapsulates consumed calories, optional TDEE, and all derived display values.
/// Views must not compute these values independently — use this struct (SSOT, DRY).
struct CaloriePillData: Equatable {
    // MARK: - Core Properties

    /// Total calories consumed from AI-analyzed meals today (or for a historical day).
    let consumed: Int

    /// Total Daily Energy Expenditure in Cal.
    /// `nil` means the user has not set up a health profile — triggers "Set up profile" state.
    let tdee: Int?

    /// When `true`, `consumed` is a partial sum — not all meals have been AI-analyzed.
    /// The pill displays a "~" prefix to indicate the estimate may be incomplete.
    var isPartial: Bool = false

    // MARK: - Derived: Visibility

    /// Whether the pill should be shown at all.
    /// Hidden only when `consumed == 0` AND `tdee == nil` (Zen empty-day state).
    /// Visible when `consumed == 0 && tdee != nil` — shows "0 / 2,250 Cal" daily target.
    var isVisible: Bool {
        self.consumed > 0 || self.tdee != nil
    }

    // MARK: - Derived: Progress

    /// Fraction of TDEE consumed, clamped to [0, 1].
    /// Returns 0.0 when TDEE is nil (no denominator available).
    var progressFraction: Double {
        guard let tdee, tdee > 0 else { return 0.0 }
        return min(1.0, Double(self.consumed) / Double(tdee))
    }

    // MARK: - Derived: Fill Color

    /// Color of the liquid fill behind the pill text.
    /// Color constants come from `AppTheme.CaloriePill`; thresholds (business logic) come from `ScoringThresholds`.
    /// Falls back to `fillOnTrack` when TDEE is nil (no fill shown since progressFraction == 0).
    var fillColor: Color {
        guard self.tdee != nil else { return AppTheme.CaloriePill.fillOnTrack }
        if self.progressFraction >= ScoringThresholds.caloriePillOverFraction {
            return AppTheme.CaloriePill.fillOver
        } else if self.progressFraction >= ScoringThresholds.caloriePillApproachingFraction {
            return AppTheme.CaloriePill.fillApproaching
        } else {
            return AppTheme.CaloriePill.fillOnTrack
        }
    }

    // MARK: - Derived: Formatted Strings

    /// Locale-aware formatted consumed calories, e.g. "1,250".
    /// Prefixed with "~" when `isPartial` is true (not all meals AI-analyzed).
    var formattedConsumed: String {
        let raw = Self.calorieFormatter.string(from: NSNumber(value: self.consumed)) ?? "\(self.consumed)"
        return self.isPartial ? "~\(raw)" : raw
    }

    /// Locale-aware formatted TDEE, e.g. "2,250". `nil` when TDEE is unknown.
    var formattedTDEE: String? {
        guard let tdee else { return nil }
        return Self.calorieFormatter.string(from: NSNumber(value: tdee)) ?? "\(tdee)"
    }

    /// Calories remaining to reach TDEE goal. Negative when over goal.
    /// `nil` when TDEE is unknown (no profile set up).
    var remaining: Int? {
        guard let tdee else { return nil }
        return tdee - self.consumed
    }

    /// Locale-aware formatted absolute remaining calories, prefixed with "-" when over goal.
    /// `nil` when TDEE is unknown.
    var formattedRemaining: String? {
        guard let remaining else { return nil }
        let abs = Swift.abs(remaining)
        let formatted = Self.calorieFormatter.string(from: NSNumber(value: abs)) ?? "\(abs)"
        return remaining >= 0 ? formatted : "-\(formatted)"
    }

    /// Formats any calorie integer using the shared locale-aware formatter.
    /// Use this in views that display per-meal calorie values.
    static func formatted(_ calories: Int) -> String {
        self.calorieFormatter.string(from: NSNumber(value: calories)) ?? "\(calories)"
    }

    // MARK: - Private Helpers

    /// Shared number formatter — integer, locale-aware grouping separator.
    private static let calorieFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
}
