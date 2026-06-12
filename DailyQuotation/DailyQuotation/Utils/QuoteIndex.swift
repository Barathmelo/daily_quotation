import Foundation

/// Lazy-built, immutable view of `LocalQuotes.quotes` powering the Explore
/// tab. Construction touches all 10k quotes once and is O(n); after that
/// every lookup is dictionary-cheap. Search is also O(n) per query but
/// stays well under 100ms for the current corpus on a modern device.
@MainActor
final class QuoteIndex {
  static let shared = QuoteIndex()

  let allQuotes: [Quote]
  let byCategory: [String: [Quote]]
  let byAuthor: [String: [Quote]]

  /// Categories sorted by quote count descending.
  let topCategories: [(name: String, count: Int)]

  /// Authors sorted by quote count descending.
  let topAuthors: [(name: String, count: Int)]

  private init() {
    let quotes = LocalQuotes.quotes
    self.allQuotes = quotes

    var byCat: [String: [Quote]] = [:]
    var byAuth: [String: [Quote]] = [:]
    for q in quotes {
      if let raw = q.category?.trimmingCharacters(in: .whitespacesAndNewlines),
         !raw.isEmpty {
        byCat[raw, default: []].append(q)
      }
      let author = q.author.trimmingCharacters(in: .whitespacesAndNewlines)
      if !author.isEmpty {
        byAuth[author, default: []].append(q)
      }
    }
    self.byCategory = byCat
    self.byAuthor = byAuth

    self.topCategories = byCat
      .map { (name: $0.key, count: $0.value.count) }
      .sorted { $0.count > $1.count }

    self.topAuthors = byAuth
      .map { (name: $0.key, count: $0.value.count) }
      .sorted { $0.count > $1.count }
  }

  /// Case-insensitive contains-match against text and author. `limit`
  /// caps the result size so the list view doesn't have to lay out
  /// thousands of rows for very common terms.
  func search(_ query: String, limit: Int = 200) -> [Quote] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }

    var results: [Quote] = []
    results.reserveCapacity(min(limit, 64))
    for q in allQuotes {
      if q.text.localizedCaseInsensitiveContains(trimmed)
        || q.author.localizedCaseInsensitiveContains(trimmed) {
        results.append(q)
        if results.count >= limit { break }
      }
    }
    return results
  }
}
