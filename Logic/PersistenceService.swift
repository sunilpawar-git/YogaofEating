import Foundation
import OSLog

private let logger = Logger(subsystem: "com.yogaofeating", category: "Persistence")

/// Serial actor that serializes all disk writes, preventing interleaved saves.
private actor PersistenceWriter {
    func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }
}

/// Handles persistent storage of app data using JSON files.
/// Saves meals and smiley state to the documents directory.
class PersistenceService: PersistenceServiceProtocol {
    static let shared = PersistenceService()

    private let fileName = "yoga_of_eating_data.json"
    private let writer = PersistenceWriter()

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

    /// Saves the current state of the app including historical data.
    /// Writes are serialized through a background actor to prevent races.
    func save(meals: [Meal], smileyState: SmileyState, lastResetDate: Date, historicalData: HistoricalData) {
        let data = AppData(
            meals: meals,
            smileyState: smileyState,
            lastResetDate: lastResetDate,
            historicalData: historicalData
        )

        Task(priority: .utility) {
            guard let url = self.fileURL else {
                logger.error("PersistenceService: could not resolve file URL — save skipped")
                return
            }
            do {
                let encoded = try JSONEncoder().encode(data)
                try await self.writer.write(encoded, to: url)
            } catch {
                logger.error("PersistenceService: save failed — \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Loads the saved state of the app
    /// Handles migration from old data format (without historicalData field)
    func load() -> AppData? {
        guard let url = fileURL else { return nil }
        // Read the file once and reuse the bytes for both decode attempts.
        guard let rawData = try? Data(contentsOf: url) else { return nil }
        do {
            let decoded = try JSONDecoder().decode(AppData.self, from: rawData)
            return decoded
        } catch let primaryError {
            // Migration fallback: attempt to decode old format without historicalData.
            logger.info("PersistenceService: primary decode failed (schema change?) — attempting migration")
            do {
                let oldData = try JSONDecoder().decode(OldAppData.self, from: rawData)
                logger.info("PersistenceService: migration from old format succeeded")
                return AppData(
                    meals: oldData.meals,
                    smileyState: oldData.smileyState,
                    lastResetDate: oldData.lastResetDate,
                    historicalData: HistoricalData()
                )
            } catch let migrationError {
                // Both the current and legacy format failed — data is unreadable.
                // Log at fault level so this appears in Crashlytics if Firebase is configured.
                logger.fault(
                    "PersistenceService: all decode attempts failed — primary: \(primaryError.localizedDescription, privacy: .public), migration: \(migrationError.localizedDescription, privacy: .public)"
                )
                return nil
            }
        }
    }

    /// Old data structure for migration (without historicalData)
    private struct OldAppData: Codable {
        let meals: [Meal]
        let smileyState: SmileyState
        let lastResetDate: Date
    }

    /// Deletes all persisted data by removing the storage file.
    /// This is a destructive operation and cannot be undone.
    func deleteAll() {
        guard let url = fileURL else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            logger.error("PersistenceService: deleteAll failed — \(error.localizedDescription, privacy: .public)")
        }
    }
}
