import Foundation
import SnapGlassCore

protocol DockReading: Sendable {
    func dockApps() throws -> [AppRecord]
}

struct DockReader: DockReading {
    func dockApps() throws -> [AppRecord] {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/com.apple.dock.plist")
        let data = try Data(contentsOf: url)
        guard
            let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let persistentApps = plist["persistent-apps"] as? [[String: Any]]
        else {
            return []
        }

        return persistentApps.compactMap(appRecord(from:))
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
