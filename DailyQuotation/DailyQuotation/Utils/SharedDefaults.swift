import Foundation
import WidgetKit

enum SharedDefaults {
  private static let appGroupIdentifier = "group.BiBoBiBo.DailyQuotation"

  static var store: UserDefaults {
    if let defaults = UserDefaults(suiteName: appGroupIdentifier) {
      return defaults
    }
    #if DEBUG
    print("⚠️ SharedDefaults: App Group \(appGroupIdentifier) unavailable, falling back to .standard")
    #endif
    return .standard
  }
}

// MARK: - First launch tracking

/// Stamps the date the user first opens the app so History Calendar
/// can lock its minimum selectable date to that day. Without this the
/// user could pick e.g. 2025-01-01 and see content they "should not"
/// have access to as a 2026 first-time user.
enum FirstLaunchTracker {
  private static let key = "firstLaunchDate"

  /// Record today as the first-launch date if we don't have one yet.
  /// Idempotent — safe to call on every cold start.
  static func recordIfNeeded(date: Date = Date()) {
    let store = SharedDefaults.store
    if store.object(forKey: key) == nil {
      store.set(Calendar.current.startOfDay(for: date), forKey: key)
    }
  }

  /// Earliest date the user can navigate to via History Calendar.
  /// Falls back to today if the stamp is somehow missing.
  static var firstLaunchDate: Date {
    (SharedDefaults.store.object(forKey: key) as? Date)
      ?? Calendar.current.startOfDay(for: Date())
  }
}

// MARK: - Daily Reminder preferences (App ↔︎ NotificationManager)

/// Three small UserDefaults entries that drive the local notification
/// scheduling. Lives in the App Group so a future widget / intent could
/// surface the same state without duplicating storage.
enum ReminderPreferences {
  private static let enabledKey = "reminder.enabled"
  private static let hourKey = "reminder.hour"
  private static let minuteKey = "reminder.minute"

  static var isEnabled: Bool {
    get { SharedDefaults.store.bool(forKey: enabledKey) }
    set { SharedDefaults.store.set(newValue, forKey: enabledKey) }
  }

  static var hour: Int {
    get { (SharedDefaults.store.object(forKey: hourKey) as? Int) ?? 9 }
    set { SharedDefaults.store.set(newValue, forKey: hourKey) }
  }

  static var minute: Int {
    get { (SharedDefaults.store.object(forKey: minuteKey) as? Int) ?? 0 }
    set { SharedDefaults.store.set(newValue, forKey: minuteKey) }
  }
}

// MARK: - Daily Quote Sync (App ↔︎ Widget)

private struct DailyQuotePayload: Codable {
  let quote: Quote
  /// Quote's position in `LocalQuotes.quotes`. Used by the widget as
  /// the gradient/image index, so the widget background lines up with
  /// the corresponding Feed slide.
  let index: Int
  let dayOfYear: Int
  let year: Int
}

enum DailyQuoteSync {
  /// File-based payload sharing. `UserDefaults` keyed via App Group
  /// suffers from heavy multi-process caching on iOS 18+: the main app's
  /// `set` + `synchronize()` writes succeed, but the widget extension
  /// reads a stale copy because each process maintains its own
  /// in-memory plist cache that the OS doesn't reliably invalidate on
  /// cross-process writes (we hit this exact symptom — see "Ignoring
  /// reloading contents for key because it's the exact same as we
  /// already have loaded" in chronod logs).
  ///
  /// A plain JSON file in the App Group container has no such cache:
  /// `Data.write(to:options:.atomic)` is durably visible to every
  /// process the instant it returns.
  private static let payloadFileName = "dailyQuoteOfToday.json"
  private static let appGroupIdentifier = "group.BiBoBiBo.DailyQuotation"

  /// Number of quotes the Feed rotates through per day. Must match
  /// `FeedViewModel.maxDailyQuotes` so the widget shows the same
  /// quote as position 0 of today's Feed.
  private static let quotesPerDay = 20

  private static var payloadURL: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
      .appendingPathComponent(payloadFileName)
  }

  /// Index of today's "Quote of the Day" within `LocalQuotes.quotes`.
  /// Algorithm mirrors `FeedViewModel.todayOrder` at position 0:
  /// `daysSinceEpoch * quotesPerDay % count`. Keeping these in sync is
  /// what makes Widget and Feed first-card show the same quote.
  static func todayIndex(date: Date = Date()) -> Int {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let epoch = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1)) ?? startOfDay
    let daysSinceStart = calendar.dateComponents([.day], from: epoch, to: startOfDay).day ?? 0
    let count = max(1, LocalQuotes.quotes.count)
    let raw = (daysSinceStart * quotesPerDay) % count
    return ((raw % count) + count) % count
  }

  /// Bootstrap path — guarantees the widget has *some* quote for today
  /// even if the user never visits the Feed tab. Idempotent: if today's
  /// payload already exists (e.g. written earlier by the Feed via
  /// `update`), we keep it so a user's refreshed quote isn't reverted.
  static func syncTodayIfNeeded(date: Date = Date()) {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let dayOfYear = calendar.ordinality(of: .day, in: .year, for: startOfDay) ?? 0
    let year = calendar.component(.year, from: startOfDay)

    if let cached = loadStoredPayload(),
      cached.dayOfYear == dayOfYear,
      cached.year == year
    {
      WidgetCenter.shared.reloadTimelines(ofKind: "DailyQuotationWidget")
      return
    }

    let index = todayIndex(date: date)
    let quote = LocalQuotes.getQuote(at: index)
    writePayload(quote: quote, index: index, dayOfYear: dayOfYear, year: year)
  }

  /// Overwrite the widget's payload to whatever the user is currently
  /// looking at. Called from `FeedView` on appear and after every
  /// refresh so the home-screen card mirrors the in-app card.
  static func update(quote: Quote, gradientIndex: Int, date: Date = Date()) {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let dayOfYear = calendar.ordinality(of: .day, in: .year, for: startOfDay) ?? 0
    let year = calendar.component(.year, from: startOfDay)

    #if DEBUG
    print("[DailyQuoteSync.update] index=\(gradientIndex) text=\"\(quote.text.prefix(40))…\"")
    #endif

    writePayload(quote: quote, index: gradientIndex, dayOfYear: dayOfYear, year: year)
  }

  /// Shared write + widget-reload path. Atomic file I/O so the widget
  /// extension always reads the fresh payload (UserDefaults cross-process
  /// caching makes that unreliable — see `payloadFileName` doc).
  private static func writePayload(quote: Quote, index: Int, dayOfYear: Int, year: Int) {
    let payload = DailyQuotePayload(
      quote: quote,
      index: index,
      dayOfYear: dayOfYear,
      year: year
    )

    guard let data = try? JSONEncoder().encode(payload) else {
      #if DEBUG
      print("[DailyQuoteSync] ⚠️ encode failed")
      #endif
      return
    }

    guard let url = payloadURL else {
      #if DEBUG
      print("[DailyQuoteSync] ⚠️ no App Group container URL — payload not written")
      #endif
      return
    }

    do {
      try data.write(to: url, options: .atomic)
    } catch {
      #if DEBUG
      print("[DailyQuoteSync] ⚠️ file write failed: \(error)")
      #endif
      return
    }

    // Reload everything we own. `ofKind:` should be enough but
    // `reloadAllTimelines` is more robust on the simulator where the
    // kind-filtered call sometimes silently no-ops.
    WidgetCenter.shared.reloadAllTimelines()

    #if DEBUG
    print("[DailyQuoteSync] wrote payload (\(data.count) bytes) → \(url.lastPathComponent), reloadAllTimelines requested")
    #endif
  }

  static func loadTodayQuote(date: Date = Date()) -> Quote? {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let dayOfYear = calendar.ordinality(of: .day, in: .year, for: startOfDay) ?? 0
    let year = calendar.component(.year, from: startOfDay)

    guard let payload = loadStoredPayload(),
      payload.dayOfYear == dayOfYear,
      payload.year == year
    else {
      return nil
    }
    return payload.quote
  }

  private static func loadStoredPayload() -> DailyQuotePayload? {
    guard let url = payloadURL,
      let data = try? Data(contentsOf: url)
    else { return nil }
    return try? JSONDecoder().decode(DailyQuotePayload.self, from: data)
  }
}
