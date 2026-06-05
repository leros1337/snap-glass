import Foundation

public protocol ManualShortcutPersisting: Sendable {
    func load() throws -> [ManualShortcut]
    func save(_ shortcuts: [ManualShortcut]) throws
}

public final class ManualShortcutStore: ManualShortcutPersisting, @unchecked Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public static func defaultStore() throws -> ManualShortcutStore {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = support.appendingPathComponent("SnapGlass", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return ManualShortcutStore(fileURL: directory.appendingPathComponent("manual-shortcuts.json"))
    }

    public func load() throws -> [ManualShortcut] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([ManualShortcut].self, from: data)
    }

    public func save(_ shortcuts: [ManualShortcut]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(shortcuts)
        try data.write(to: fileURL, options: [.atomic])
    }
}

