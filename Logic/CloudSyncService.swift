import FirebaseFirestore
import Foundation

/// Protocol for cloud synchronization service
protocol CloudSyncServiceProtocol {
    func upload(snapshot: DailySmileySnapshot, userId: String) async throws
    func fetchAll(userId: String) async throws -> [DailySmileySnapshot]
}

/// Service for interacting with Firebase Firestore to sync heatmap data.
class CloudSyncService: CloudSyncServiceProtocol {
    // Lazy initialization to prevent crash when Firebase isn't configured (e.g., unit tests)
    private lazy var db: Firestore? = {
        if NSClassFromString("XCTestCase") != nil {
            return nil
        }
        return Firestore.firestore()
    }()

    private let collectionName = "heatmap_snapshots"

    /// Uploads a single snapshot to Firestore.
    /// Uses the normalized date string as the document ID to prevent duplicates.
    func upload(snapshot: DailySmileySnapshot, userId: String) async throws {
        guard let db = self.db else {
            // Skip during unit tests
            print("☁️ CloudSync: Skipping upload (no db - likely unit test)")
            return
        }
        let dateString = self.dateFormatter.string(from: snapshot.date)
        let docPath = "users/\(userId)/\(self.collectionName)/\(dateString)"
        print("☁️ CloudSync: Uploading to \(docPath)")

        let docRef = db.collection("users").document(userId)
            .collection(self.collectionName).document(dateString)

        let data = try self.encode(snapshot)

        do {
            try await docRef.setData(data)
            print("☁️ CloudSync: Successfully uploaded \(dateString)")
        } catch {
            print("☁️ CloudSync: Upload FAILED for \(dateString)")
            print("☁️ CloudSync: Error type: \(type(of: error))")
            print("☁️ CloudSync: Error: \(error)")
            throw error
        }
    }

    /// Fetches all snapshots for a given user from Firestore.
    func fetchAll(userId: String) async throws -> [DailySmileySnapshot] {
        guard let db = self.db else {
            // Return empty during unit tests
            return []
        }
        let querySnapshot = try await db.collection("users").document(userId)
            .collection(self.collectionName)
            .getDocuments()

        return try querySnapshot.documents.compactMap { document in
            try self.decode(document.data())
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
            throw NSError(
                domain: "CloudSyncService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to serialize snapshot"]
            )
        }
        return dictionary
    }

    private func decode(_ dictionary: [String: Any]) throws -> DailySmileySnapshot {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try JSONDecoder().decode(DailySmileySnapshot.self, from: data)
    }
}
