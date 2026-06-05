import Testing
@testable import SnapGlassCore

@Test func dockAssignmentsMapFirstNineAppsToOneThroughNineAndTenthToZero() {
    let apps = (1...11).map {
        AppRecord(name: "App \($0)", bundleIdentifier: "test.app.\($0)", path: "/Applications/App\($0).app")
    }

    let assignments = ShortcutPlanner().dockAssignments(for: apps, modifier: .command)

    #expect(assignments.count == 10)
    #expect(assignments.map(\.key) == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
    #expect(assignments.map(\.displayShortcut).last == "⌘0")
}

@Test func manualAssignmentsOverrideDockAssignmentsWithSameShortcut() {
    let safari = AppRecord(name: "Safari", bundleIdentifier: "com.apple.Safari", path: "/Applications/Safari.app")
    let mail = AppRecord(name: "Mail", bundleIdentifier: "com.apple.mail", path: "/Applications/Mail.app")
    let manual = ShortcutAssignment(app: mail, modifier: .command, key: "1", source: .manual)
    let dock = ShortcutAssignment(app: safari, modifier: .command, key: "1", source: .dock)

    let assignments = ShortcutPlanner().mergedAssignments(dock: [dock], manual: [manual])

    #expect(assignments == [manual])
}

