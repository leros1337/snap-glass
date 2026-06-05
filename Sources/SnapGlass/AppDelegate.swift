import AppKit
import SnapGlassCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var coordinator: ShortcutCoordinator?
    private var preferencesWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = (try? ManualShortcutStore.defaultStore())
            ?? ManualShortcutStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("snapglass-shortcuts.json"))
        let coordinator = ShortcutCoordinator(
            dockReader: DockReader(),
            store: store,
            launcher: WorkspaceAppLauncher(),
            registrar: CarbonHotKeyRegistrar()
        )
        self.coordinator = coordinator

        setStatusIconVisible(AppSettings.isStatusIconVisible)
        coordinator.reload()

        if !AppSettings.isStatusIconVisible {
            showPreferences()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPreferences()
        return false
    }

    private func setStatusIconVisible(_ isVisible: Bool) {
        AppSettings.isStatusIconVisible = isVisible
        if isVisible {
            configureStatusItem()
        } else if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    private func configureStatusItem() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "sparkle.magnifyingglass", accessibilityDescription: "SnapGlass")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "About SnapGlass", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Reload Dock Shortcuts", action: #selector(reloadShortcuts), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit SnapGlass", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    @objc private func showPreferences() {
        guard let coordinator else { return }
        if preferencesWindow == nil {
            let view = PreferencesView(
                model: PreferencesModel(
                    coordinator: coordinator,
                    statusIconVisibilityChanged: { [weak self] isVisible in
                        self?.setStatusIconVisible(isVisible)
                    }
                )
            )
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 760, height: 520),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "SnapGlass"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.delegate = self
            window.contentView = NSHostingView(rootView: view)
            preferencesWindow = window
        }

        preferencesWindow?.center()
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    @objc private func reloadShortcuts() {
        coordinator?.reload()
    }

    @objc private func showAbout() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

        let alert = NSAlert()
        alert.messageText = "SnapGlass"
        alert.informativeText = """
        Version \(version) (\(build))

        https://github.com/leros1337/snap-glass
        """
        alert.icon = NSImage(named: "SnapGlassIcon") ?? NSApp.applicationIconImage
        alert.addButton(withTitle: "Open GitHub")
        alert.addButton(withTitle: "OK")

        if alert.runModal() == .alertFirstButtonReturn {
            openGitHub()
        }
    }

    @objc private func openGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/leros1337/snap-glass")!)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
