import Combine
import Foundation
import WidgetKit

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
    // The widget reads appearance from this same SharedDefaults entry,
    // so we need to nudge WidgetKit to re-evaluate the timeline.
    // Without this, theme/font/size changes only reach the widget on
    // its next scheduled refresh (00:05 next day) — visibly stale.
    WidgetCenter.shared.reloadAllTimelines()
  }

  func updateSettings(_ newSettings: AppearanceSettings) {
    settings = newSettings
    saveSettings()
  }
}
