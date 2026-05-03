import FirebaseCore
import FirebaseFirestore
import Foundation
import OSLog

private let syncLogger = Logger(subsystem: "com.yogaofeating", category: "CloudSync")

/// Protocol for cloud synchronization service
protocol CloudSyncServiceProtocol {
    func upload(snapshot: DailySmileySnapshot, userId: String) async throws
    func uploadBatch(snapshots: [DailySmileySnapshot], userId: String) async throws
}

/// Service for interacting with Firebase Firestore to sync heatmap data.
class CloudSyncService: CloudSyncServiceProtocol {
    // Only initialise Firestore when Firebase is actually configured.
    // In tests, inject MockCloudSyncService — never rely on runtime class-name detection here.
    private lazy var db: Firestore? = {
        guard FirebaseApp.app() != nil else { return nil }
        return Firestore.firestore()
    }()

    private let collectionName = "heatmap_snapshots"

    /// Uploads a single snapshot to Firestore.
    /// Uses the normalized date string as the document ID to prevent duplicates.
    func upload(snapshot: DailySmileySnapshot, userId: String) async throws {
        guard let db = self.db else { return }
        let dateString = self.dateFormatter.string(from: snapshot.date)
        syncLogger.debug("Uploading snapshot for \(dateString, privacy: .public)")

        let docRef = db.collection("users").document(userId)
            .collection(self.collectionName).document(dateString)

        let data = try self.encode(snapshot)

        do {
            try await docRef.setData(data)
            syncLogger.debug("Upload succeeded for \(dateString, privacy: .public)")
        } catch {
            syncLogger
                .error(
                    "Upload failed for \(dateString, privacy: .public): \(error.localizedDescription, privacy: .public)"
                )
            throw error
        }
    }

    /// Uploads multiple snapshots to Firestore in batches.
    /// Splits large uploads into chunks of 500 to respect Firestore batch limits.
    func uploadBatch(snapshots: [DailySmileySnapshot], userId: String) async throws {
        guard let db = self.db else { return }

        let batchSize = 500
        let chunks = stride(from: 0, to: snapshots.count, by: batchSize).map { startIndex in
            Array(snapshots[startIndex..<min(startIndex + batchSize, snapshots.count)])
        }

        for (index, chunk) in chunks.enumerated() {
            let batch = db.batch()

            for snapshot in chunk {
                let dateString = self.dateFormatter.string(from: snapshot.date)
                let docRef = db.collection("users").document(userId)
                    .collection(self.collectionName).document(dateString)
                let data = try self.encode(snapshot)
                batch.setData(data, forDocument: docRef)
            }

            do {
                try await batch.commit()
                syncLogger.debug("Batch \(index + 1) committed successfully with \(chunk.count) snapshots")
            } catch {
                syncLogger.error("Batch \(index + 1) commit failed: \(error.localizedDescription, privacy: .public)")
                throw error
            }
        }
    }

    // MARK: - Helpers

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private func encode(_ snapshot: DailySmileySnapshot) throws -> [String: Any] {
        let data = try JSONEncoder().encode(snapshot)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AppError.syncSerializationFailed
        }
        return dictionary
    }

    private func decode(_ dictionary: [String: Any]) throws -> DailySmileySnapshot {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try JSONDecoder().decode(DailySmileySnapshot.self, from: data)
    }
}
