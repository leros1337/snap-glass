import Foundation
import Observation
import SnapGlassCore

@MainActor
@Observable
final class ShortcutCoordinator {
    private(set) var dockAssignments: [ShortcutAssignment] = []
    private(set) var manualShortcuts: [ManualShortcut] = []
    private(set) var errorMessage: String?
    var automaticModifier: ShortcutModifier {
        didSet {
            guard oldValue != automaticModifier else { return }
            AppSettings.automaticModifier = automaticModifier
            reload()
        }
    }

    @ObservationIgnored private let dockReader: DockReading
    @ObservationIgnored private let store: ManualShortcutPersisting
    @ObservationIgnored private let launcher: AppLaunching
    @ObservationIgnored private let registrar: HotKeyRegistering
    @ObservationIgnored private let planner = ShortcutPlanner()
    @ObservationIgnored private var dockApps: [AppRecord] = []

    init(
        dockReader: DockReading,
        store: ManualShortcutPersisting,
        launcher: AppLaunching,
        registrar: HotKeyRegistering
    ) {
        self.dockReader = dockReader
        self.store = store
        self.launcher = launcher
        self.registrar = registrar
        self.automaticModifier = AppSettings.automaticModifier
    }

    var allAssignments: [ShortcutAssignment] {
        planner.mergedAssignments(
            dock: dockAssignments,
            manual: planner.manualAssignments(from: manualShortcuts)
        )
    }

    /// Re-reads the manual shortcut file and the Dock, then re-registers all hotkeys.
    func reload() {
        do {
            manualShortcuts = try store.load()
            dockApps = try dockReader.dockApps()
            try registerAll()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addManualShortcut(_ shortcut: ManualShortcut) {
        manualShortcuts.removeAll { $0.id == shortcut.id }
        manualShortcuts.append(shortcut)
        manualShortcuts.sort { $0.app.name.localizedCaseInsensitiveCompare($1.app.name) == .orderedAscending }
        persistManualShortcuts()
    }

    func removeManualShortcut(_ shortcut: ManualShortcut) {
        manualShortcuts.removeAll { $0.id == shortcut.id }
        persistManualShortcuts()
    }

    func restoreDefaults() {
        do {
            try store.save([])
            manualShortcuts = []
            // Assigning the modifier triggers `didSet`, which reloads once when the value changes.
            // If it was already `.command`, reload explicitly so the cleared manual shortcuts unregister.
            let needsExplicitReload = automaticModifier == .command
            automaticModifier = .command
            if needsExplicitReload {
                reload()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Persists the in-memory manual shortcuts and re-registers hotkeys without re-reading from disk.
    private func persistManualShortcuts() {
        do {
            try store.save(manualShortcuts)
            try registerAll()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Plans Dock assignments from the cached Dock apps and registers every hotkey.
    private func registerAll() throws {
        dockAssignments = planner.dockAssignments(for: dockApps, modifier: automaticModifier)
        try registrar.register(assignments: allAssignments) { [weak self] assignment in
            self?.launcher.activateOrPeek(assignment.app)
        }
    }
}
