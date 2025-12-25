import Foundation

/// Represents a single meal entry in the "Yoga of Eating".
struct Meal: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    var description: String
    var healthScore: Double // 0.0 (unhealthy) to 1.0 (very healthy)

    init(id: UUID = UUID(), timestamp: Date = Date(), description: String = "", healthScore: Double = 0.5) {
        self.id = id
        self.timestamp = timestamp
        self.description = description
        self.healthScore = healthScore
    }
}
