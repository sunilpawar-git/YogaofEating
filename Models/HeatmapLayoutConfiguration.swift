import Foundation
import SwiftUI

/// Represents the grid direction for the heatmap layout.
enum HeatmapGridDirection: Equatable {
    /// Vertical layout: 7 columns (days of week), 53 rows (weeks of year)
    /// Best for portrait orientation on mobile devices.
    case vertical

    /// Horizontal layout: 7 rows (days of week), 53 columns (weeks of year)
    /// Best for landscape orientation or wider screens.
    case horizontal
}

/// Configuration for the heatmap layout that adapts to screen size and orientation.
/// This struct calculates optimal cell sizes, spacing, and grid dimensions
/// based on available screen real estate while ensuring thumb-friendly tap targets.
struct HeatmapLayoutConfiguration {
    // MARK: - Constants

    /// Minimum cell size for comfortable tapping (Apple HIG recommends 44pt, we use 32pt as compromise)
    let minimumCellSize: CGFloat = 32

    /// Maximum cell size to prevent cells from becoming too large on iPads
    let maximumCellSize: CGFloat = 50

    /// Standard spacing between cells
    let spacing: CGFloat = 4

    /// Number of days in a week (columns in portrait, rows in landscape)
    private let daysPerWeek: Int = 7

    /// Maximum weeks in a year (rows in portrait, columns in landscape)
    private let weeksPerYear: Int = 53

    // MARK: - Input Properties

    /// Screen width in points
    private let screenWidth: CGFloat

    /// Screen height in points
    private let screenHeight: CGFloat

    /// Whether the device is in portrait orientation
    private let isPortrait: Bool

    /// Horizontal padding (left + right) to account for safe areas and margins
    private let horizontalPadding: CGFloat

    /// Vertical padding reserved for header, legend, and other UI elements
    private let verticalPadding: CGFloat

    // MARK: - Computed Properties

    /// The calculated cell size based on screen dimensions and orientation.
    /// Guaranteed to be between `minimumCellSize` and `maximumCellSize`.
    var cellSize: CGFloat {
        let calculatedSize: CGFloat

        if self.isPortrait {
            // In portrait, fit 7 columns within available width
            let availableWidth = self.screenWidth - self.horizontalPadding
            let spacingTotal = self.spacing * CGFloat(self.daysPerWeek - 1)
            calculatedSize = (availableWidth - spacingTotal) / CGFloat(self.daysPerWeek)
        } else {
            // In landscape, fit 7 rows within available height
            let availableHeight = self.screenHeight - self.verticalPadding
            let spacingTotal = self.spacing * CGFloat(self.daysPerWeek - 1)
            calculatedSize = (availableHeight - spacingTotal) / CGFloat(self.daysPerWeek)
        }

        // Clamp between minimum and maximum
        return min(self.maximumCellSize, max(self.minimumCellSize, calculatedSize))
    }

    /// The grid direction based on device orientation.
    var gridDirection: HeatmapGridDirection {
        self.isPortrait ? .vertical : .horizontal
    }

    /// Corner radius proportional to cell size (10% with minimum of 3pt).
    var cornerRadius: CGFloat {
        max(3, self.cellSize * 0.1)
    }

    /// Total width of the grid including all cells and spacing.
    var totalGridWidth: CGFloat {
        if self.isPortrait {
            // 7 columns
            (self.cellSize * CGFloat(self.daysPerWeek)) + (self.spacing * CGFloat(self.daysPerWeek - 1))
        } else {
            // 53 columns
            (self.cellSize * CGFloat(self.weeksPerYear)) + (self.spacing * CGFloat(self.weeksPerYear - 1))
        }
    }

    /// Total height of the grid including all cells and spacing.
    var totalGridHeight: CGFloat {
        if self.isPortrait {
            // 53 rows
            (self.cellSize * CGFloat(self.weeksPerYear)) + (self.spacing * CGFloat(self.weeksPerYear - 1))
        } else {
            // 7 rows
            (self.cellSize * CGFloat(self.daysPerWeek)) + (self.spacing * CGFloat(self.daysPerWeek - 1))
        }
    }

    /// Number of columns in the grid.
    var columnCount: Int {
        self.isPortrait ? self.daysPerWeek : self.weeksPerYear
    }

    /// Number of rows in the grid.
    var rowCount: Int {
        self.isPortrait ? self.weeksPerYear : self.daysPerWeek
    }

    // MARK: - Initialization

    /// Creates a new layout configuration.
    /// - Parameters:
    ///   - screenWidth: The available screen width in points.
    ///   - screenHeight: The available screen height in points.
    ///   - isPortrait: Whether the device is in portrait orientation.
    ///   - horizontalPadding: Total horizontal padding (left + right). Defaults to 32pt.
    ///   - verticalPadding: Vertical space reserved for UI elements. Defaults to 150pt.
    init(
        screenWidth: CGFloat,
        screenHeight: CGFloat,
        isPortrait: Bool,
        horizontalPadding: CGFloat = 32,
        verticalPadding: CGFloat = 150
    ) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.isPortrait = isPortrait
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }
}

// MARK: - SwiftUI Grid Item Helpers

extension HeatmapLayoutConfiguration {
    /// Creates an array of GridItems for use with LazyVGrid (portrait) or LazyHGrid (landscape).
    var gridItems: [GridItem] {
        let count = self.isPortrait ? self.daysPerWeek : self.daysPerWeek
        return Array(
            repeating: GridItem(.fixed(self.cellSize), spacing: self.spacing),
            count: count
        )
    }
}
