import Foundation

enum SettingsKey {
    static let defaultWakeDuration = "defaultWakeDuration"
    static let activateOnLaunch = "activateOnLaunch"
}

enum AppSettings {
    static var defaultWakeDuration: WakeDuration {
        let raw = UserDefaults.standard.object(forKey: SettingsKey.defaultWakeDuration) as? Int
            ?? WakeDuration.oneHour.rawValue
        return WakeDuration(rawValue: raw) ?? .oneHour
    }

    static var activateOnLaunch: Bool {
        UserDefaults.standard.bool(forKey: SettingsKey.activateOnLaunch)
    }
}
