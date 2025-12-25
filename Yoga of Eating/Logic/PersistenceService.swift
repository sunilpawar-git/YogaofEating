import Foundation

/// Handles persistent storage of app data using JSON files.
/// Saves meals and smiley state to the documents directory.
class PersistenceService {
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
    }

    /// Saves the current state of the app
    func save(meals: [Meal], smileyState: SmileyState, lastResetDate: Date) {
        let data = AppData(meals: meals, smileyState: smileyState, lastResetDate: lastResetDate)

        Task(priority: .background) {
            guard let url = self.fileURL else { return }
            do {
                let encoded = try JSONEncoder().encode(data)
                try encoded.write(to: url, options: .atomic)
                print("Saved data to \(url.path)")
            } catch {
                print("Failed to save data: \(error)")
            }
        }
    }

    /// Loads the saved state of the app
    func load() -> AppData? {
        guard let url = fileURL else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(AppData.self, from: data)
            print("Loaded data from \(url.path)")
            return decoded
        } catch {
            print("Failed to load data (might be first run): \(error)")
            return nil
        }
    }
}
