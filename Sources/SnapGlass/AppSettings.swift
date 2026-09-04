import Foundation
import SnapGlassCore

enum AppSettings {
    private static let statusIconVisibleKey = "statusIconVisible"
    private static let automaticModifierKey = "automaticModifier"

    private static var defaults: UserDefaults { .standard }

    static var isStatusIconVisible: Bool {
        get {
            guard defaults.object(forKey: statusIconVisibleKey) != nil else {
                return true
            }
            return defaults.bool(forKey: statusIconVisibleKey)
        }
        set {
            defaults.set(newValue, forKey: statusIconVisibleKey)
        }
    }

    static var automaticModifier: ShortcutModifier {
        get {
            defaults.string(forKey: automaticModifierKey)
                .flatMap(ShortcutModifier.init(rawValue:)) ?? .command
        }
        set {
            defaults.set(newValue.rawValue, forKey: automaticModifierKey)
        }
    }

    static func reset() {
        defaults.removeObject(forKey: statusIconVisibleKey)
        defaults.removeObject(forKey: automaticModifierKey)
    }
}
