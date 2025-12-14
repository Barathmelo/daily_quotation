import Foundation

final class AccessControl {
  static let shared = AccessControl()

  // Limits
  private let freeFavoriteLimit = 3
  private let freeDailyViewLimit = 3
  private let premiumDailyViewLimit = 20

  private let storage = UserDefaults.standard
  private let viewCountKey = "dailyViewCount"
  private let viewDateKey = "dailyViewDate"

  private init() {}

  // MARK: - Daily View
  func resetIfNeeded(date: Date = Date()) {
    let today = startOfDay(date)
    if let stored = storage.object(forKey: viewDateKey) as? Date {
      if startOfDay(stored) != today {
        storage.set(0, forKey: viewCountKey)
        storage.set(today, forKey: viewDateKey)
      }
    } else {
      storage.set(today, forKey: viewDateKey)
      storage.set(0, forKey: viewCountKey)
    }
  }

  func registerViewIfAllowed(isPremium: Bool) -> Bool {
    resetIfNeeded()
    let limit = isPremium ? premiumDailyViewLimit : freeDailyViewLimit
    let count = storage.integer(forKey: viewCountKey)
    guard count < limit else { return false }
    storage.set(count + 1, forKey: viewCountKey)
    return true
  }

  var remainingViews: Int {
    resetIfNeeded()
    let count = storage.integer(forKey: viewCountKey)
    return max(0, freeDailyViewLimit - count)
  }

  // MARK: - Favorites
  func canAddFavorite(currentCount: Int, isPremium: Bool) -> Bool {
    if isPremium { return true }
    return currentCount < freeFavoriteLimit
  }

  // MARK: - Fonts
  func canUseFont(font: FontFamily, isPremium: Bool) -> Bool {
    if isPremium { return true }
    return font == AppearanceSettings.default.font
  }

  // MARK: - Helpers
  private func startOfDay(_ date: Date) -> Date {
    Calendar.current.startOfDay(for: date)
  }
}

