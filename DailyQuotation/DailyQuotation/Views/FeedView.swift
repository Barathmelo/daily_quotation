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
  private let maxDailyQuotes = 20
  private let freeScrollAllowance = 1

  var body: some View {
    GeometryReader { geometry in
      let screenHeight = geometry.size.height
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
        Color.black.ignoresSafeArea(.all)

        ZStack {
          if let prevPos {
            if hasEndCard && prevPos == orderCount {
              endCard(offset: -screenHeight + downDragAmount, screenHeight: screenHeight)
                .opacity(isDragging && dragOffset > 0 ? max(0, downProgress) : 0)
                .zIndex(0)
            } else if let prevIndex = quoteIndex(at: prevPos, in: order) {
              quoteCard(at: prevIndex, isFirstOfDay: false, offset: -screenHeight + downDragAmount, screenHeight: screenHeight)
                .opacity(isDragging && dragOffset > 0 ? max(0, downProgress) : 0)
                .zIndex(0)
            }
          }

          if isCurrentEndCard {
            endCard(offset: dragOffset, screenHeight: screenHeight)
              .zIndex(1)
          } else {
            quoteCard(at: currentQuoteIndex, isFirstOfDay: currentPosition == 0, offset: dragOffset, screenHeight: screenHeight)
              .zIndex(1)
          }

          if let nextPos {
            if hasEndCard && nextPos == orderCount {
              endCard(offset: screenHeight - upDragAmount, screenHeight: screenHeight)
                .opacity(isDragging && dragOffset < 0 ? max(0, upProgress) : 0)
                .zIndex(0)
            } else if let nextIndex = quoteIndex(at: nextPos, in: order) {
              quoteCard(at: nextIndex, isFirstOfDay: false, offset: screenHeight - upDragAmount, screenHeight: screenHeight)
                .opacity(isDragging && dragOffset < 0 ? max(0, upProgress) : 0)
                .zIndex(0)
            }
          }
        }
        .gesture(
          DragGesture(minimumDistance: 20)
            .onChanged { value in
              if abs(value.translation.height) > abs(value.translation.width) {
                if !isDragging {
                  isDragging = true
                }
                dragOffset = value.translation.height
              }
            }
            .onEnded { value in
              let dragThreshold: CGFloat = screenHeight * 0.25
              if value.translation.height < -dragThreshold
                || value.predictedEndTranslation.height < -dragThreshold
              {
                let nextPos = currentPosition + 1

                if !subscriptionManager.isPremiumUser && nextPos >= freeScrollAllowance {
                  withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    dragOffset = 0
                  }
                  onRequirePaywall()
                  isDragging = false
                  return
                }

                if nextPos < totalPositions {
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
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                  dragOffset = 0
                }
              }

              isDragging = false
            }
        )
      }
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
  private func quoteCard(at index: Int, isFirstOfDay: Bool, offset: CGFloat, screenHeight: CGFloat) -> some View {
    if quotes.isEmpty {
      EmptyView()
    } else {
      let actualIndex = ((index % quotes.count) + quotes.count) % quotes.count
      let quote = quotes[actualIndex]

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
    }
  }

  private var todayOrder: [Int] {
    guard !quotes.isEmpty else { return [] }

    let calendar = Calendar.current
    let now = Date()
    let startOfDay = calendar.startOfDay(for: now)

    let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
    let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: startOfDay).day ?? 0

    let quotesPerDay = subscriptionManager.isPremiumUser ? maxDailyQuotes : freeScrollAllowance
    let totalQuotes = quotes.count

    let startIndex = (daysSinceStart * quotesPerDay) % totalQuotes

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

  private func endCard(offset: CGFloat, screenHeight: CGFloat) -> some View {
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
