import AppKit
import SnapGlassCore

protocol AppLaunching: Sendable {
    @MainActor func activateOrPeek(_ app: AppRecord)
}

final class WorkspaceAppLauncher: AppLaunching, @unchecked Sendable {
    private var lastActivatedBundleID: String?
    private var lastActivationDate: Date = .distantPast

    @MainActor
    func activateOrPeek(_ app: AppRecord) {
        if
            let bundleIdentifier = app.bundleIdentifier,
            let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
        {
            if lastActivatedBundleID == bundleIdentifier && Date().timeIntervalSince(lastActivationDate) < 1.2 {
                running.hide()
                lastActivatedBundleID = nil
                return
            }

            running.activate(options: [.activateAllWindows])
            lastActivatedBundleID = bundleIdentifier
            lastActivationDate = Date()
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: app.path),
            configuration: configuration
        ) { [weak self] application, _ in
            guard let self, let application else { return }
            Task { @MainActor in
                self.lastActivatedBundleID = application.bundleIdentifier
                self.lastActivationDate = Date()
            }
        }
    }
}
