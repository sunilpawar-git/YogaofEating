import SwiftUI

/// Represents the four daily modules in the radial home screen.
/// Single source of truth for module identity, ordering, display names, and colors.
enum DayModule: Int, CaseIterable, Identifiable {
    case reflect = 0
    case laser = 1
    case highlight = 2
    case energise = 3

    var id: Int { self.rawValue }

    var title: String {
        switch self {
        case .reflect: Strings.DayRing.reflect
        case .laser: Strings.DayRing.laser
        case .highlight: Strings.DayRing.highlight
        case .energise: Strings.DayRing.energise
        }
    }

    var color: Color {
        switch self {
        case .reflect: AppTheme.ModuleColors.reflect
        case .laser: AppTheme.ModuleColors.laser
        case .highlight: AppTheme.ModuleColors.highlight
        case .energise: AppTheme.ModuleColors.energise
        }
    }

    var icon: String {
        switch self {
        case .reflect: "sunrise"
        case .laser: "scope"
        case .highlight: "star"
        case .energise: "bolt.heart"
        }
    }
}
