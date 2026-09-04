import Foundation
import SnapGlassCore

protocol DockReading: Sendable {
    func dockApps() throws -> [AppRecord]
}

struct DockReader: DockReading {
    private static let dockDomain = "com.apple.dock"
    private static let persistentAppsKey = "persistent-apps"

    func dockApps() throws -> [AppRecord] {
        let persistentApps = try preferencePersistentApps() ?? filePersistentApps()
        return (persistentApps ?? []).compactMap(appRecord(from:))
    }

    /// Reads the live value through `cfprefsd`, which owns the Dock preferences and may not have
    /// flushed recent changes to disk yet.
    private func preferencePersistentApps() -> [[String: Any]]? {
        CFPreferencesCopyAppValue(
            Self.persistentAppsKey as CFString,
            Self.dockDomain as CFString
        ) as? [[String: Any]]
    }

    /// Fallback for environments where the preference domain is not readable.
    private func filePersistentApps() throws -> [[String: Any]]? {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/\(Self.dockDomain).plist")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        return plist?[Self.persistentAppsKey] as? [[String: Any]]
    }

    private func appRecord(from tile: [String: Any]) -> AppRecord? {
        guard let tileData = tile["tile-data"] as? [String: Any] else { return nil }
        let name = tileData["file-label"] as? String
        let bundleIdentifier = tileData["bundle-identifier"] as? String
        let path = ((tileData["file-data"] as? [String: Any])?["_CFURLString"] as? String)
            .flatMap { URL(string: $0)?.path(percentEncoded: false) }

        guard let resolvedPath = path else { return nil }
        return AppRecord(
            name: name ?? URL(fileURLWithPath: resolvedPath).deletingPathExtension().lastPathComponent,
            bundleIdentifier: bundleIdentifier,
            path: resolvedPath
        )
    }
}
