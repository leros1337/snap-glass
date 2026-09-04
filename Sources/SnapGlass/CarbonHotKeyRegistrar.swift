import Carbon.HIToolbox
import Foundation
import SnapGlassCore

protocol HotKeyRegistering: Sendable {
    @MainActor func register(
        assignments: [ShortcutAssignment],
        handler: @escaping @MainActor (ShortcutAssignment) -> Void
    ) throws
}

@MainActor
final class CarbonHotKeyRegistrar: HotKeyRegistering {
    private var hotKeys: [EventHotKeyRef?] = []
    private var assignmentsByID: [UInt32: ShortcutAssignment] = [:]
    private var handler: (@MainActor (ShortcutAssignment) -> Void)?
    private var eventHandler: EventHandlerRef?

    isolated deinit {
        for case let hotKey? in hotKeys {
            UnregisterEventHotKey(hotKey)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    func register(
        assignments: [ShortcutAssignment],
        handler: @escaping @MainActor (ShortcutAssignment) -> Void
    ) throws {
        unregisterAll()
        self.handler = handler
        installHandlerIfNeeded()

        for (index, assignment) in assignments.enumerated() {
            guard let keyCode = assignment.key.carbonKeyCode else { continue }
            let id = UInt32(index + 1)
            let hotKeyID = EventHotKeyID(signature: OSType(fourCharCode("SNPG")), id: id)
            var hotKeyRef: EventHotKeyRef?
            let status = RegisterEventHotKey(
                keyCode,
                assignment.modifier.carbonModifier,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )
            guard status == noErr else { continue }
            hotKeys.append(hotKeyRef)
            assignmentsByID[id] = assignment
        }
    }

    private func unregisterAll() {
        for hotKey in hotKeys {
            if let hotKey {
                UnregisterEventHotKey(hotKey)
            }
        }
        hotKeys.removeAll()
        assignmentsByID.removeAll()
    }

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }
                let registrar = Unmanaged<CarbonHotKeyRegistrar>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                // Handlers on the application event target are always invoked on the main thread,
                // so dispatching a Task per key press is unnecessary.
                MainActor.assumeIsolated {
                    registrar.fire(id: hotKeyID.id)
                }
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )
    }

    private func fire(id: UInt32) {
        guard let assignment = assignmentsByID[id] else { return }
        handler?(assignment)
    }
}

private func fourCharCode(_ string: String) -> FourCharCode {
    string.utf8.reduce(0) { ($0 << 8) + FourCharCode($1) }
}

private extension ShortcutModifier {
    var carbonModifier: UInt32 {
        switch self {
        case .command: UInt32(cmdKey)
        case .option: UInt32(optionKey)
        case .control: UInt32(controlKey)
        case .shift: UInt32(shiftKey)
        }
    }
}

private extension String {
    var carbonKeyCode: UInt32? {
        switch uppercased() {
        case "0": 29
        case "1": 18
        case "2": 19
        case "3": 20
        case "4": 21
        case "5": 23
        case "6": 22
        case "7": 26
        case "8": 28
        case "9": 25
        case "A": 0
        case "B": 11
        case "C": 8
        case "D": 2
        case "E": 14
        case "F": 3
        case "G": 5
        case "H": 4
        case "I": 34
        case "J": 38
        case "K": 40
        case "L": 37
        case "M": 46
        case "N": 45
        case "O": 31
        case "P": 35
        case "Q": 12
        case "R": 15
        case "S": 1
        case "T": 17
        case "U": 32
        case "V": 9
        case "W": 13
        case "X": 7
        case "Y": 16
        case "Z": 6
        default: nil
        }
    }
}
