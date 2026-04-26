import Foundation

enum WidgetDataProvider {
    static let fileName = "widget_snapshot.json"

    static func load(
        from containerURL: URL? = appGroupContainerURL()
    ) -> WidgetSnapshot {
        guard let containerURL else { return .empty }

        let fileURL = containerURL.appendingPathComponent(Self.fileName)

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(
                WidgetSnapshot.self, from: data
            )
        } catch {
            return .empty
        }
    }

    static func appGroupContainerURL() -> URL? {
        // NOTE: Keep in sync with StorageKeys.appGroupIdentifier in the main app target.
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier:
            "group.com.yogaofeating.shared"
        )
    }
}
