import AppKit
import ServiceManagement
import SnapGlassCore

@MainActor
final class PreferencesModel: ObservableObject {
    @Published var selectedApp: AppRecord?
    @Published var selectedModifier: ShortcutModifier = .option
    @Published var selectedKey = "A"
    @Published var launchAtLogin: Bool {
        didSet {
            updateLaunchAtLogin()
        }
    }
    @Published var showStatusIcon: Bool {
        didSet {
            guard !isResetting else { return }
            AppSettings.isStatusIconVisible = showStatusIcon
            statusIconVisibilityChanged(showStatusIcon)
        }
    }
    @Published var settingsError: String?

    let coordinator: ShortcutCoordinator
    private let statusIconVisibilityChanged: (Bool) -> Void
    private var isSyncingLaunchAtLogin = false
    private var isResetting = false

    init(
        coordinator: ShortcutCoordinator,
        statusIconVisibilityChanged: @escaping (Bool) -> Void
    ) {
        self.coordinator = coordinator
        self.statusIconVisibilityChanged = statusIconVisibilityChanged
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.showStatusIcon = AppSettings.isStatusIconVisible
    }

    var installedApps: [AppRecord] {
        let directories = [
            "/Applications",
            "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications",
            "/System/Applications",
            "/System/Applications/Utilities"
        ]
        let urls = directories.flatMap { directory -> [URL] in
            (try? FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: directory),
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            )) ?? []
        }

        return urls
            .filter { $0.pathExtension == "app" }
            .map { url in
                let bundle = Bundle(url: url)
                let name = (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? url.deletingPathExtension().lastPathComponent
                return AppRecord(name: name, bundleIdentifier: bundle?.bundleIdentifier, path: url.path)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
