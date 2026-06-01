import SwiftUI

struct FeedView: View {
  @ObservedObject var favoritesManager = FavoritesManager.shared
  @Binding var appearance: AppearanceSettings
  @Binding var persistedIndex: Int
  @EnvironmentObject private var subscriptionManager: SubscriptionManager
  var onRequirePaywall: () -> Void = {}
  @State private var currentPosition: Int = 0
  @State private var furthestPosition: Int = 0
  @State private var dragOffset: CGFloat = 0
  @State private var isDragging: Bool = false

  private let quotes = LocalQuotes.quotes
  private let screenHeight = UIScreen.main.bounds.height
  private let maxDailyQuotes = 20
  private let freeScrollAllowance = 1

  var body: some View {
    let order = todayOrder
    let orderCount = order.count
    let hasEndCard = subscriptionManager.isPremiumUser && orderCount >= maxDailyQuotes
    let totalPositions = orderCount + (hasEndCard ? 1 : 0)

    let isCurrentEndCard = hasEndCard && currentPosition == orderCount
    let prevPos = currentPosition > 0 ? currentPosition - 1 : nil
    let nextPos = currentPosition + 1 < totalPositions ? currentPosition + 1 : nil
    let currentQuoteIndex = quoteIndex(at: currentPosition, in: order) ?? 0

    let upDragAmount = max(0, -dragOffset)
    let downDragAmount = max(0, dragOffset)
    let upProgress = min(1, upDragAmount / screenHeight)
    let downProgress = min(1, downDragAmount / screenHeight)

    ZStack {
      // Background
      Color.black.ignoresSafeArea(.all)

      // Quote cards stack
      ZStack {
        if let prevPos {
          if hasEndCard && prevPos == orderCount {
            endCard(offset: -screenHeight + downDragAmount)
              .opacity(isDragging && dragOffset > 0 ? max(0, downProgress) : 0)
              .zIndex(0)
          } else if let prevIndex = quoteIndex(at: prevPos, in: order) {
            quoteCard(at: prevIndex, isFirstOfDay: false, offset: -screenHeight + downDragAmount)
              .opacity(isDragging && dragOffset > 0 ? max(0, downProgress) : 0)
              .zIndex(0)
          }
        }

        // Current card
        if isCurrentEndCard {
          endCard(offset: dragOffset)
            .zIndex(1)
        } else {
          quoteCard(at: currentQuoteIndex, isFirstOfDay: currentPosition == 0, offset: dragOffset)
            .zIndex(1)
        }

        // Next card
        if let nextPos {
          if hasEndCard && nextPos == orderCount {
            endCard(offset: screenHeight - upDragAmount)
              .opacity(isDragging && dragOffset < 0 ? max(0, upProgress) : 0)
              .zIndex(0)
          } else if let nextIndex = quoteIndex(at: nextPos, in: order) {
            quoteCard(at: nextIndex, isFirstOfDay: false, offset: screenHeight - upDragAmount)
              .opacity(isDragging && dragOffset < 0 ? max(0, upProgress) : 0)
              .zIndex(0)
          }
        }
      }
      .gesture(
        DragGesture(minimumDistance: 20)
          .onChanged { value in
            // Only respond to vertical drags (not horizontal)
            if abs(value.translation.height) > abs(value.translation.width) {
              if !isDragging {
                isDragging = true
              }

              dragOffset = value.translation.height
            }
          }
          .onEnded { value in
            let dragThreshold: CGFloat = screenHeight * 0.25
            let isFirst = currentPosition == 0
            if value.translation.height < -dragThreshold
              || value.predictedEndTranslation.height < -dragThreshold
            {
              // Swipe up → go forward (cap at end)
              let nextPos = currentPosition + 1

              // 免费用户：严格限制在前3条（position 0, 1, 2）
              if !subscriptionManager.isPremiumUser && nextPos >= freeScrollAllowance {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                  dragOffset = 0
                }
                onRequirePaywall()
                isDragging = false
                return
              }

              if nextPos < totalPositions {
                // 更新最远位置
                if nextPos > furthestPosition {
                  furthestPosition = nextPos
                }

                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                  currentPosition = nextPos
                  dragOffset = 0
                }
                HapticManager.medium()
              } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                  dragOffset = 0
                }
                HapticManager.light()
              }
            } else if value.translation.height > dragThreshold
              || value.predictedEndTranslation.height > dragThreshold
            {
              // Swipe down → go back (blocked on first)
              if currentPosition > 0 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                  currentPosition -= 1
                  dragOffset = 0
                }
                HapticManager.medium()
              } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                  dragOffset = 0
                }
                HapticManager.light()
              }
            } else {
              // Spring back
              withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                dragOffset = 0
              }
            }

            isDragging = false
          }
      )
    }
    .ignoresSafeArea(.all)
    .onAppear {
      AccessControl.shared.resetIfNeeded()
      let count = todayOrder.count + endCardAllowance
      guard count > 0 else {
        currentPosition = 0
        furthestPosition = 0
        return
      }
      let clampedIndex = min(persistedIndex, count - 1)
      currentPosition = clampedIndex
      furthestPosition = max(furthestPosition, clampedIndex)
    }
    .onChange(of: persistedIndex) { newValue in
      currentPosition = min(newValue, todayOrder.count + endCardAllowance - 1)
    }
    .onChange(of: currentPosition) { newValue in
      persistedIndex = newValue
    }
    .onChange(of: currentDayOfYear) { _ in
      currentPosition = 0
      persistedIndex = 0
      furthestPosition = 0
      AccessControl.shared.resetIfNeeded()
    }
  }

  @ViewBuilder
  private func quoteCard(at index: Int, isFirstOfDay: Bool, offset: CGFloat) -> some View {
    // Handle negative indices for infinite loop and ensure array is not empty
    if quotes.isEmpty {
      return AnyView(EmptyView())
    } else {
      let actualIndex = ((index % quotes.count) + quotes.count) % quotes.count
      let quote = quotes[actualIndex]
      let todayIndex = DailyQuoteSync.todayIndex()

      return AnyView(
        QuoteSlideView(
          quote: quote,
          index: actualIndex,
          isToday: isFirstOfDay,
          isPremium: subscriptionManager.isPremiumUser,
          onRequirePaywall: onRequirePaywall,
          onToggleFavorite: {
            let allowed = AccessControl.shared.canAddFavorite(
              currentCount: favoritesManager.favorites.count,
              isPremium: subscriptionManager.isPremiumUser)
            if allowed {
              favoritesManager.toggleFavorite(quote)
            } else {
              onRequirePaywall()
            }
          },
          appearance: $appearance
        )
        .offset(y: offset)
        .scaleEffect(1.0 - abs(offset) / (screenHeight * 2))
        .opacity(1.0 - abs(offset) / (screenHeight * 1.5))
      )
    }
  }

  private var todayOrder: [Int] {
    guard !quotes.isEmpty else { return [] }

    let calendar = Calendar.current
    let now = Date()
    let startOfDay = calendar.startOfDay(for: now)

    // 计算从起始日期（2025年1月1日）到今天经过了多少天
    let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
    let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: startOfDay).day ?? 0

    let quotesPerDay = subscriptionManager.isPremiumUser ? maxDailyQuotes : freeScrollAllowance
    let totalQuotes = quotes.count

    // 计算今天应该从哪个索引开始（顺序消费）
    let startIndex = (daysSinceStart * quotesPerDay) % totalQuotes

    // 生成连续的索引数组
    var result: [Int] = []
    for i in 0..<quotesPerDay {
      let index = (startIndex + i) % totalQuotes
      result.append(index)
    }

    return result
  }

  private var currentDayOfYear: Int {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())
    return calendar.ordinality(of: .day, in: .year, for: startOfDay) ?? 0
  }

  private func quoteIndex(at position: Int, in order: [Int]) -> Int? {
    guard position >= 0, position < order.count else { return nil }
    return order[position]
  }

  private var endCardAllowance: Int {
    (subscriptionManager.isPremiumUser && todayOrder.count >= maxDailyQuotes) ? 1 : 0
  }

  private func endCard(offset: CGFloat) -> some View {
    VStack(spacing: 10) {
      Text("That's it for now.")
        .font(.system(size: 26, weight: .bold))
        .foregroundColor(.white)
      Text("You've reached the end of this collection.\nCheck back tomorrow for more.")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.white.opacity(0.78))
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
    .offset(y: offset)
    .opacity(1.0 - abs(offset) / (screenHeight * 1.5))
  }
}
