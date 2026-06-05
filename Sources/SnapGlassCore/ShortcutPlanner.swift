import Foundation

public struct ShortcutPlanner: Sendable {
    public init() {}

    public func dockAssignments(
        for apps: [AppRecord],
        modifier: ShortcutModifier,
        maxSlots: Int = 10
    ) -> [ShortcutAssignment] {
        Array(apps.prefix(maxSlots)).enumerated().map { index, app in
            let key = index == 9 ? "0" : String(index + 1)
            return ShortcutAssignment(app: app, modifier: modifier, key: key, source: .dock)
        }
    }

    public func manualAssignments(from shortcuts: [ManualShortcut]) -> [ShortcutAssignment] {
        shortcuts.map {
            ShortcutAssignment(app: $0.app, modifier: $0.modifier, key: $0.key, source: .manual)
        }
    }

    public func mergedAssignments(
        dock: [ShortcutAssignment],
        manual: [ShortcutAssignment]
    ) -> [ShortcutAssignment] {
        var seen = Set<String>()
        return (manual + dock).filter { assignment in
            let signature = "\(assignment.modifier.rawValue)-\(assignment.key)"
            return seen.insert(signature).inserted
        }
    }
}

