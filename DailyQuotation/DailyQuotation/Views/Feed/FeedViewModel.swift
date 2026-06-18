import Combine
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
  /// Anchor date for the 20-quote rotation. `@Published` so that the
  /// hosting view re-renders (and `todayOrder` recomputes) when the
  /// calling view re-pins the rotation to a new day — e.g. after the
  /// app crosses midnight while still on the Feed tab.
  @Published private(set) var referenceDate: Date

  let isPremium: Bool

  private let quotes: [Quote]
  private let maxDailyQuotes = 20
  private let freeScrollAllowance = 1

  init(
    isPremium: Bool,
    referenceDate: Date = Date(),
    quotes: [Quote]? = nil
  ) {
    self.isPremium = isPremium
    self.referenceDate = referenceDate
    self.quotes = quotes ?? LocalQuotes.quotes
  }

  /// Re-pin the rotation to the given date.
  ///
  /// `FeedView` calls this when it detects that the calendar day has
  /// changed since the view model was constructed (the user left the
  /// Feed on screen across midnight). Without this, `todayOrder` stays
  /// frozen on yesterday's sequence and position 0 reads as yesterday's
  /// "Quote of the Day". `HistoryFeedView` deliberately *does not* call
  /// this so historical days stay pinned.
  func updateReferenceDate(_ date: Date) {
    referenceDate = date
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
