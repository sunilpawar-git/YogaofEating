import Foundation

/// Generic average helper — eliminates repeated reduce-divide expressions (DRY principle).
extension Collection where Element: BinaryFloatingPoint {
    /// Returns the arithmetic mean of all elements, or `nil` for an empty collection.
    func average() -> Element? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Element(count)
    }
}
