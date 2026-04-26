import Foundation

struct WidgetSnapshot: Codable, Equatable {
    let overallProgress: Double
    let bisScore: Double
    let streak: Int
    let date: Date

    static let empty = WidgetSnapshot(
        overallProgress: 0, bisScore: 0, streak: 0, date: .distantPast
    )
}
