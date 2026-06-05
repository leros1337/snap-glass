import Foundation
import SnapGlassCore

@MainActor
final class ShortcutCoordinator: ObservableObject {
    @Published private(set) var dockAssignments: [ShortcutAssignment] = []
    @Published private(set) var manualShortcuts: [ManualShortcut] = []
    @Published private(set) var errorMessage: String?
    @Published var automaticModifier: ShortcutModifier = .command {
        didSet { reload() }
    }

    private let dockReader: DockReading
    private let store: ManualShortcutPersisting
    private let launcher: AppLaunching
    private let registrar: HotKeyRegistering
    private let planner = ShortcutPlanner()

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
    }

    var allAssignments: [ShortcutAssignment] {
        planner.mergedAssignments(
            dock: dockAssignments,
            manual: planner.manualAssignments(from: manualShortcuts)
        )
    }

    func reload() {
        do {
            manualShortcuts = try store.load()
            let dockApps = try dockReader.dockApps()
            dockAssignments = planner.dockAssignments(for: dockApps, modifier: automaticModifier)
            try registrar.register(assignments: allAssignments) { [weak self] assignment in
                self?.launcher.activateOrPeek(assignment.app)
            }
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
            automaticModifier = .command
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persistManualShortcuts() {
        do {
            try store.save(manualShortcuts)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
