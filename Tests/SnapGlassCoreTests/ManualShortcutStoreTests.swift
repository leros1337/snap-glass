import Foundation
import Testing
@testable import SnapGlassCore

@Test func manualShortcutStoreRoundTripsShortcuts() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let store = ManualShortcutStore(fileURL: directory.appendingPathComponent("shortcuts.json"))
    let app = AppRecord(name: "Terminal", bundleIdentifier: "com.apple.Terminal", path: "/Applications/Utilities/Terminal.app")
    let shortcuts = [ManualShortcut(app: app, modifier: .option, key: "T")]

    try store.save(shortcuts)

    #expect(try store.load() == shortcuts)
}

@Test func missingManualShortcutFileLoadsEmptyList() throws {
    let store = ManualShortcutStore(
        fileURL: FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("missing.json")
    )

    #expect(try store.load().isEmpty)
}

