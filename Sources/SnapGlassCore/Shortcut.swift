import Foundation

public enum ShortcutModifier: String, Codable, CaseIterable, Sendable, Identifiable {
    case command
    case option
    case control
    case shift

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .command: "Command"
        case .option: "Option"
        case .control: "Control"
        case .shift: "Shift"
        }
    }

    public var symbol: String {
        switch self {
        case .command: "⌘"
        case .option: "⌥"
        case .control: "⌃"
        case .shift: "⇧"
        }
    }
}

public struct AppRecord: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String { bundleIdentifier ?? path }
    public let name: String
    public let bundleIdentifier: String?
    public let path: String

    public init(name: String, bundleIdentifier: String?, path: String) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
    }
}

public struct ShortcutAssignment: Codable, Equatable, Identifiable, Sendable {
    public enum Source: String, Codable, Sendable {
        case dock
        case manual
    }

    public var id: String {
        "\(source.rawValue)-\(modifier.rawValue)-\(key)-\(app.id)"
    }

    public let app: AppRecord
    public let modifier: ShortcutModifier
    public let key: String
    public let source: Source

    public init(app: AppRecord, modifier: ShortcutModifier, key: String, source: Source) {
        self.app = app
        self.modifier = modifier
        self.key = key
        self.source = source
    }

    public var displayShortcut: String {
        "\(modifier.symbol)\(key)"
    }
}

public struct ManualShortcut: Codable, Equatable, Identifiable, Sendable {
    public var id: String { app.id }
    public let app: AppRecord
    public var modifier: ShortcutModifier
    public var key: String

    public init(app: AppRecord, modifier: ShortcutModifier, key: String) {
        self.app = app
        self.modifier = modifier
        self.key = key
    }
}
