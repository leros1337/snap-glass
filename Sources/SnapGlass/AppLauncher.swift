import AppKit
import SnapGlassCore

protocol AppLaunching: Sendable {
    @MainActor func activateOrPeek(_ app: AppRecord)
}

@MainActor
final class WorkspaceAppLauncher: AppLaunching {
    private static let peekWindow: TimeInterval = 1.2

    private var lastActivatedBundleID: String?
    private var lastActivationDate: Date = .distantPast

    func activateOrPeek(_ app: AppRecord) {
        if
            let bundleIdentifier = app.bundleIdentifier,
            let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
        {
            if lastActivatedBundleID == bundleIdentifier && Date().timeIntervalSince(lastActivationDate) < Self.peekWindow {
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
        ) { application, _ in
            guard let application else { return }
            let bundleIdentifier = application.bundleIdentifier
            Task { @MainActor [weak self] in
                self?.lastActivatedBundleID = bundleIdentifier
                self?.lastActivationDate = Date()
            }
        }
    }
}
