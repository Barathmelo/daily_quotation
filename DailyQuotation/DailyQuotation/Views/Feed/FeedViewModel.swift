import Foundation
import SwiftUI

/// Owns the data + paging + gating logic for `FeedView`.
///
/// `FeedView` is responsible only for rendering and gesture handling;
/// every decision about which quote to show, whether the user is allowed
/// to advance, and whether the end card should appear lives here.
@MainActor
final class FeedViewModel: ObservableObject {
  @Published var currentPosition: Int = 0
  @Published var furthestPosition: Int = 0

  let isPremium: Bool

  private let quotes: [Quote]
  private let referenceDate: Date
  private let maxDailyQuotes = 20
  private let freeScrollAllowance = 1

  init(
    isPremium: Bool,
    referenceDate: Date = Date(),
    quotes: [Quote] = LocalQuotes.quotes
  ) {
    self.isPremium = isPremium
    self.referenceDate = referenceDate
    self.quotes = quotes
  }

  // MARK: - Derived state

  var quotesPerDay: Int {
    isPremium ? maxDailyQuotes : freeScrollAllowance
  }

  var todayOrder: [Int] {
    guard !quotes.isEmpty else { return [] }

    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: referenceDate)
    let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
    let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: startOfDay).day ?? 0
    let totalQuotes = quotes.count

    let startIndex = (daysSinceStart * quotesPerDay) % totalQuotes
    return (0..<quotesPerDay).map { (startIndex + $0) % totalQuotes }
  }

  var hasEndCard: Bool {
    isPremium && todayOrder.count >= maxDailyQuotes
  }

  var totalPositions: Int {
    todayOrder.count + (hasEndCard ? 1 : 0)
  }

  /// `true` if `position` corresponds to the trailing "That's it for now" card.
  func isEndCard(at position: Int) -> Bool {
    hasEndCard && position == todayOrder.count
  }

  /// Whether the user is permitted to advance from `position`.
  /// Free users are blocked after the first quote regardless of `totalPositions`.
  func canMoveForward(from position: Int) -> Bool {
    let nextPos = position + 1
    if !isPremium && nextPos >= freeScrollAllowance {
      return false
    }
    return nextPos < totalPositions
  }

  /// The raw `LocalQuotes.quotes` index for a given feed position, or `nil`
  /// if the position is the end card (or otherwise out of range).
  func quoteIndex(at position: Int) -> Int? {
    let order = todayOrder
    guard position >= 0, position < order.count else { return nil }
    return order[position]
  }

  func quote(at position: Int) -> Quote? {
    guard let idx = quoteIndex(at: position), !quotes.isEmpty else { return nil }
    let actual = ((idx % quotes.count) + quotes.count) % quotes.count
    return quotes[actual]
  }
}
