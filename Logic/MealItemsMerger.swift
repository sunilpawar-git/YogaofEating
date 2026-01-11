import Foundation

/// Helper for merging meal items with deduplication.
/// Used by the Recent Meals feature to append items without duplicates.
enum MealItemsMerger {
    /// Merges new items into existing items, avoiding duplicates.
    /// Comparison is case-insensitive and whitespace-trimmed.
    /// - Parameters:
    ///   - existing: The current items in the meal
    ///   - new: The items to add from a recent meal
    /// - Returns: Combined items with duplicates removed
    static func merge(existing: [String], new: [String]) -> [String] {
        guard !existing.isEmpty else {
            return new
        }

        // Create a set of normalized existing items for O(1) lookup
        let existingSet = Set(existing.map { self.normalizeItem($0) })

        // Filter new items that aren't duplicates
        let uniqueNewItems = new.filter { item in
            !existingSet.contains(self.normalizeItem(item))
        }

        return existing + uniqueNewItems
    }

    /// Normalizes an item for comparison (lowercase, trimmed whitespace)
    private static func normalizeItem(_ item: String) -> String {
        item.lowercased().trimmingCharacters(in: .whitespaces)
    }
}

