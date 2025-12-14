import Combine
import Foundation

class AppearanceManager: ObservableObject {

  static let shared = AppearanceManager()

  private let storageKey = "dailyWisdomAppearance"
  private let defaults = SharedDefaults.store

  @Published var settings: AppearanceSettings = AppearanceSettings.default

  private init() {
    loadSettings()
  }

  func loadSettings() {
    guard let data = defaults.data(forKey: storageKey),
      let decoded = try? JSONDecoder().decode(AppearanceSettings.self, from: data)
    else {
      settings = AppearanceSettings.default
      return
    }
    settings = decoded
  }

  func saveSettings() {
    guard let data = try? JSONEncoder().encode(settings) else { return }
    defaults.set(data, forKey: storageKey)
  }

  func updateSettings(_ newSettings: AppearanceSettings) {
    settings = newSettings
    saveSettings()
  }
}
