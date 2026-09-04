import AppKit
import Observation
import ServiceManagement
import SnapGlassCore

@MainActor
@Observable
final class PreferencesModel {
    var selectedApp: AppRecord?
    var selectedModifier: ShortcutModifier = .option
    var selectedKey = "A"
    var launchAtLogin: Bool {
        didSet {
            updateLaunchAtLogin()
        }
    }
    var showStatusIcon: Bool {
        didSet {
            guard !isResetting else { return }
            AppSettings.isStatusIconVisible = showStatusIcon
            statusIconVisibilityChanged(showStatusIcon)
        }
    }
    var settingsError: String?

    /// Installed applications, loaded once in the background rather than on every view update.
    private(set) var installedApps: [AppRecord] = []
    private(set) var isLoadingApps = false

    let coordinator: ShortcutCoordinator
    @ObservationIgnored private let statusIconVisibilityChanged: (Bool) -> Void
    @ObservationIgnored private var isSyncingLaunchAtLogin = false
    @ObservationIgnored private var isResetting = false
    @ObservationIgnored private var appScanTask: Task<Void, Never>?

    init(
        coordinator: ShortcutCoordinator,
        statusIconVisibilityChanged: @escaping (Bool) -> Void
    ) {
        self.coordinator = coordinator
        self.statusIconVisibilityChanged = statusIconVisibilityChanged
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.showStatusIcon = AppSettings.isStatusIconVisible
        refreshInstalledApps()
    }

    deinit {
        appScanTask?.cancel()
    }

    /// Scans the standard application folders off the main thread and publishes the result once.
    func refreshInstalledApps() {
        guard appScanTask == nil else { return }
        isLoadingApps = true
        appScanTask = Task.detached(priority: .utility) { [weak self] in
            let apps = InstalledAppScanner.scan()
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.installedApps = apps
                self.isLoadingApps = false
                self.appScanTask = nil
            }
        }
    }

    func addSelectedShortcut() {
        guard let selectedApp else { return }
        coordinator.addManualShortcut(
            ManualShortcut(app: selectedApp, modifier: selectedModifier, key: selectedKey)
        )
    }

    func restoreDefaults() {
        isResetting = true
        settingsError = nil
        selectedApp = nil
        selectedModifier = .option
        selectedKey = "A"

        AppSettings.reset()
        showStatusIcon = AppSettings.isStatusIconVisible
        statusIconVisibilityChanged(showStatusIcon)

        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = false
        } catch {
            settingsError = error.localizedDescription
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }

        coordinator.restoreDefaults()
        isResetting = false
    }

    private func updateLaunchAtLogin() {
        guard !isSyncingLaunchAtLogin, !isResetting else { return }
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            settingsError = nil
        } catch {
            settingsError = error.localizedDescription
            isSyncingLaunchAtLogin = true
            launchAtLogin = SMAppService.mainApp.status == .enabled
            isSyncingLaunchAtLogin = false
        }
    }
}

/// Enumerates `.app` bundles without instantiating `Bundle` objects. `Bundle(url:)` populates a
/// process-wide CFBundle cache that is never released, so reading each Info.plist directly keeps
/// the scan from growing the app's resident memory.
enum InstalledAppScanner {
    static let searchDirectories: [URL] = [
        URL(fileURLWithPath: "/Applications", isDirectory: true),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
        URL(fileURLWithPath: "/System/Applications", isDirectory: true),
        URL(fileURLWithPath: "/System/Applications/Utilities", isDirectory: true)
    ]

    static func scan(directories: [URL] = searchDirectories) -> [AppRecord] {
        let fileManager = FileManager.default
        var seenPaths = Set<String>()
        var records: [AppRecord] = []

        for directory in directories {
            let urls = (try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            )) ?? []

            for url in urls where isApplication(url) {
                let path = url.path(percentEncoded: false)
                guard seenPaths.insert(path).inserted else { continue }
                records.append(record(for: url, path: path))
            }
        }

        return records.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Some system apps (for example cryptex-backed Safari) report `isApplication == false`,
    /// so the bundle extension remains the primary signal.
    private static func isApplication(_ url: URL) -> Bool {
        if url.pathExtension == "app" { return true }
        return (try? url.resourceValues(forKeys: [.isApplicationKey]).isApplication) ?? false
    }

    private static func record(for url: URL, path: String) -> AppRecord {
        let info = CFBundleCopyInfoDictionaryForURL(url as CFURL) as? [String: Any] ?? [:]
        let name = (info["CFBundleDisplayName"] as? String)
            ?? (info["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent
        return AppRecord(
            name: name,
            bundleIdentifier: info["CFBundleIdentifier"] as? String,
            path: path
        )
    }
}
