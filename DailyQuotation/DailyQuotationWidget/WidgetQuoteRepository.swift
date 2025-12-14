import Foundation

#if canImport(UIKit)
  import UIKit
#endif

enum WidgetQuoteRepository {
  private static let syncKey = "dailyQuoteOfToday"

  private struct DailyQuotePayload: Codable {
    let quote: Quote
    let dayOfYear: Int
    let year: Int
  }

  /// 尝试加载与主 App 相同的 quotes.json（需将资源勾选到 Widget target）
  private static let quotes: [Quote] = {
    if let loaded = loadQuotesFromBundle(), !loaded.isEmpty {
      return loaded
    }
    return []
  }()

  static func quoteOfToday(for date: Date = Date()) -> Quote {
    // 优先读取 App 同步过来的今日 Quote
    if let stored = loadStoredQuote(for: date) {
      return stored
    }

    // 没有共享数据时，按本地 quotes 计算；若仍不可用，再用占位
    guard !quotes.isEmpty else { return .placeholder }
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let dayOfYear = calendar.ordinality(of: .day, in: .year, for: startOfDay) ?? 0
    let index = dayOfYear % quotes.count
    return quotes[index]
  }

  private static func loadStoredQuote(for date: Date) -> Quote? {
    let defaults = WidgetSharedDefaults.store
    guard let data = defaults.data(forKey: syncKey),
      let payload = try? JSONDecoder().decode(DailyQuotePayload.self, from: data)
    else {
      return nil
    }

    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let dayOfYear = calendar.ordinality(of: .day, in: .year, for: startOfDay) ?? 0
    let year = calendar.component(.year, from: startOfDay)

    guard payload.dayOfYear == dayOfYear, payload.year == year else {
      return nil
    }
    return payload.quote
  }

  // MARK: - Load quotes.json from widget bundle (shared with App)
  private static func loadQuotesFromBundle() -> [Quote]? {
    #if canImport(UIKit)
      // 优先尝试 NSDataAsset（若 quotes 被加入 Widget 的 Asset Catalog）
      if let dataAsset = NSDataAsset(name: "quotes") {
        if let quotes = decodeQuotes(from: dataAsset.data) {
          return quotes
        }
      }
    #endif
    // 其次尝试直接读取资源文件
    if let url = Bundle.main.url(forResource: "quotes", withExtension: "json") {
      if let data = try? Data(contentsOf: url),
        let quotes = decodeQuotes(from: data)
      {
        return quotes
      }
    }
    return nil
  }

  private static func decodeQuotes(from data: Data) -> [Quote]? {
    guard let records = try? JSONDecoder().decode([QuoteRecord].self, from: data) else {
      return nil
    }
    let mapped = records.compactMap { $0.toQuote() }
    return mapped.isEmpty ? nil : mapped
  }

  private struct QuoteRecord: Decodable {
    let quote: String
    let author: String
    let tags: [String]?
    let category: String?

    enum CodingKeys: String, CodingKey {
      case quote = "Quote"
      case author = "Author"
      case tags = "Tags"
      case category = "Category"
    }

    func toQuote() -> Quote? {
      let trimmedQuote = quote.trimmingCharacters(in: .whitespacesAndNewlines)
      let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmedQuote.isEmpty, !trimmedAuthor.isEmpty else { return nil }

      let categoryValue = normalizedCategory(from: self)
      return Quote(
        id: UUID().uuidString,
        text: trimmedQuote,
        author: trimmedAuthor,
        category: categoryValue
      )
    }
  }

  private static func normalizedCategory(from record: QuoteRecord) -> String? {
    if let explicit = cleaned(record.category) {
      return formatted(category: explicit)
    }

    guard let tags = record.tags else { return nil }
    for tag in tags {
      guard let cleanedTag = cleaned(tag) else { continue }
      if cleanedTag.contains("-") || cleanedTag.contains("_") { continue }
      return formatted(category: cleanedTag)
    }
    return nil
  }

  private static func cleaned(_ value: String?) -> String? {
    guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
      !trimmed.isEmpty
    else {
      return nil
    }
    return trimmed
  }

  private static func formatted(category: String) -> String {
    category.capitalized
  }
}
