import Foundation

enum AppSettings {
    private static let statusIconVisibleKey = "statusIconVisible"

    static var isStatusIconVisible: Bool {
        get {
            guard UserDefaults.standard.object(forKey: statusIconVisibleKey) != nil else {
                return true
            }
            return UserDefaults.standard.bool(forKey: statusIconVisibleKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: statusIconVisibleKey)
        }
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: statusIconVisibleKey)
    }
}
