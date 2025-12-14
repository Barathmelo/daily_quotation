import Foundation

enum WidgetAppearanceStore {
    private static let storageKey = "dailyWisdomAppearance"
    
    static func currentSettings() -> AppearanceSettings {
        let defaults = WidgetSharedDefaults.store
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(AppearanceSettings.self, from: data)
        else {
            return .default
        }
        return decoded
    }
}

