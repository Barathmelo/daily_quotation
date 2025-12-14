import Foundation
import WidgetKit

enum SharedDefaults {
  private static let appGroupIdentifier = "group.BiBoBiBo.DailyQuotation"

  static var store: UserDefaults {
    guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
      fatalError("App Group \(appGroupIdentifier) is not available. Check entitlements.")
    }
    return defaults
  }
}

// MARK: - Daily Quote Sync (App ↔︎ Widget)

private struct DailyQuotePayload: Codable {
  let quote: Quote
  let dayOfYear: Int
  let year: Int
}

enum DailyQuoteSync {
  private static let key = "dailyQuoteOfToday"

  /// 计算当天的 Quote 索引（按一年中的天数取模）
  static func todayIndex(date: Date = Date()) -> Int {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let dayOfYear = calendar.ordinality(of: .day, in: .year, for: startOfDay) ?? 0
    let count = max(1, LocalQuotes.quotes.count)
    return dayOfYear % count
  }

  /// 写入今日 Quote 到共享存储，供 Widget 读取
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
    let payload = DailyQuotePayload(quote: quote, dayOfYear: dayOfYear, year: year)

    if let data = try? JSONEncoder().encode(payload) {
      SharedDefaults.store.set(data, forKey: key)
      // Refresh widget to reflect the latest Quote of the Day immediately
      WidgetCenter.shared.reloadTimelines(ofKind: "DailyQuotationWidget")
    }
  }

  /// 读取今日已存的 Quote（供 App 内使用时保持一致）
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
    guard let data = SharedDefaults.store.data(forKey: key) else { return nil }
    return try? JSONDecoder().decode(DailyQuotePayload.self, from: data)
  }
}
