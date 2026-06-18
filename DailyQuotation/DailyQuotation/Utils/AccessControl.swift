import Foundation

final class AccessControl {
  static let shared = AccessControl()

  // Limits
  private let freeFavoriteLimit = 3
  /// How many times a free user can refresh today's quote per day.
  /// The initial "Quote of the Day" view does not count.
  private let freeDailyRefreshLimit = 1
  /// How many refreshes a premium subscriber gets per day.
  private let premiumDailyRefreshLimit = 5

  // App Group-backed so the daily refresh counter survives App
  // reinstall (which would otherwise wipe `UserDefaults.standard` and
  // hand free users a fresh quota every time they reinstall). Lines up
  // with FavoritesManager / AppearanceManager / ReminderPreferences
  // which all already share the same suite.
  private let storage = SharedDefaults.store
  private let refreshCountKey = "dailyRefreshCount"
  private let refreshDateKey = "dailyRefreshDate"

  private init() {}

  // MARK: - Daily Refresh

  /// Zero the refresh counter at the start of each day. Idempotent —
  /// safe to call on every Feed appear / view body recomputation.
  func resetIfNeeded(date: Date = Date()) {
    let today = startOfDay(date)
    if let stored = storage.object(forKey: refreshDateKey) as? Date {
      if startOfDay(stored) != today {
        storage.set(0, forKey: refreshCountKey)
        storage.set(today, forKey: refreshDateKey)
      }
    } else {
      storage.set(today, forKey: refreshDateKey)
      storage.set(0, forKey: refreshCountKey)
    }
  }

  /// Try to "spend" one refresh. Returns `true` and increments the
  /// daily counter on success; returns `false` when the per-tier limit
  /// (1 / 5) has already been reached for today.
  func registerRefreshIfAllowed(isPremium: Bool) -> Bool {
    resetIfNeeded()
    let limit = isPremium ? premiumDailyRefreshLimit : freeDailyRefreshLimit
    let count = storage.integer(forKey: refreshCountKey)
    guard count < limit else { return false }
    storage.set(count + 1, forKey: refreshCountKey)
    return true
  }

  /// Refreshes still available today for the given tier.
  func remainingRefreshes(isPremium: Bool) -> Int {
    resetIfNeeded()
    let limit = isPremium ? premiumDailyRefreshLimit : freeDailyRefreshLimit
    let count = storage.integer(forKey: refreshCountKey)
    return max(0, limit - count)
  }

  /// How many refreshes have been spent today. Used by `FeedView` to
  /// cap `persistedIndex` (recovered from a previous session) into
  /// today's reachable range.
  var refreshesUsedToday: Int {
    resetIfNeeded()
    return storage.integer(forKey: refreshCountKey)
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

  // MARK: - Themes

  /// Free users can use any theme inside the `.colors` category
  /// (Midnight / Sunset / Ocean / Forest / Aurora / Mono). All image
  /// themes (Scenery / Universe / Abstract) are premium-gated.
  func canUseTheme(theme: QuoteTheme, isPremium: Bool) -> Bool {
    if isPremium { return true }
    return theme.category == .colors
  }

  // MARK: - Helpers
  private func startOfDay(_ date: Date) -> Date {
    Calendar.current.startOfDay(for: date)
  }
}
