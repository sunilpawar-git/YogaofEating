import Foundation

/// Handles persistent storage of app data using JSON files.
/// Saves meals and smiley state to the documents directory.
class PersistenceService: PersistenceServiceProtocol {
    static let shared = PersistenceService()

    private let fileName = "yoga_of_eating_data.json"

    private var fileURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(self.fileName)
    }

    /// Data structure for serialization
    struct AppData: Codable {
        let meals: [Meal]
        let smileyState: SmileyState
        let lastResetDate: Date
        let historicalData: HistoricalData
    }

    /// Saves the current state of the app including historical data
    func save(meals: [Meal], smileyState: SmileyState, lastResetDate: Date, historicalData: HistoricalData) {
        let data = AppData(
            meals: meals,
            smileyState: smileyState,
            lastResetDate: lastResetDate,
            historicalData: historicalData
        )

        Task(priority: .background) {
            guard let url = self.fileURL else { return }
            do {
                let encoded = try JSONEncoder().encode(data)
                try encoded.write(to: url, options: .atomic)
            } catch {
                // Silently fail or log to a proper logging service
            }
        }
    }

    /// Loads the saved state of the app
    /// Handles migration from old data format (without historicalData field)
    func load() -> AppData? {
        guard let url = fileURL else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(AppData.self, from: data)
            return decoded
        } catch {
            // Try loading old format without historicalData (migration)
            if let data = try? Data(contentsOf: url),
               let oldData = try? JSONDecoder().decode(OldAppData.self, from: data)
            {
                return AppData(
                    meals: oldData.meals,
                    smileyState: oldData.smileyState,
                    lastResetDate: oldData.lastResetDate,
                    historicalData: HistoricalData() // Empty historical data for migration
                )
            }
            return nil
        }
    }

    /// Old data structure for migration (without historicalData)
    private struct OldAppData: Codable {
        let meals: [Meal]
        let smileyState: SmileyState
        let lastResetDate: Date
    }
}
