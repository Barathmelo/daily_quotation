import SwiftUI

struct FeedView: View {
  @StateObject private var viewModel: FeedViewModel
  @ObservedObject var favoritesManager = FavoritesManager.shared
  @Binding var appearance: AppearanceSettings
  @Binding var persistedIndex: Int
  @EnvironmentObject private var subscriptionManager: SubscriptionManager
  var onRequirePaywall: () -> Void = {}

  @State private var dragOffset: CGFloat = 0
  @State private var isDragging: Bool = false

  init(
    appearance: Binding<AppearanceSettings>,
    persistedIndex: Binding<Int>,
    isPremium: Bool,
    onRequirePaywall: @escaping () -> Void
  ) {
    self._appearance = appearance
    self._persistedIndex = persistedIndex
    self.onRequirePaywall = onRequirePaywall
    self._viewModel = StateObject(wrappedValue: FeedViewModel(isPremium: isPremium))
  }

  var body: some View {
    GeometryReader { geometry in
      let screenHeight = geometry.size.height
      let totalPositions = viewModel.totalPositions
      let currentPosition = viewModel.currentPosition

      let prevPos = currentPosition > 0 ? currentPosition - 1 : nil
      let nextPos = currentPosition + 1 < totalPositions ? currentPosition + 1 : nil

      let upDragAmount = max(0, -dragOffset)
      let downDragAmount = max(0, dragOffset)
      let upProgress = min(1, upDragAmount / screenHeight)
      let downProgress = min(1, downDragAmount / screenHeight)

      ZStack {
        Color.black.ignoresSafeArea(.all)

        ZStack {
          if let prevPos {
            card(at: prevPos, offset: -screenHeight + downDragAmount, screenHeight: screenHeight)
              .opacity(isDragging && dragOffset > 0 ? max(0, downProgress) : 0)
              .zIndex(0)
          }

          card(at: currentPosition, offset: dragOffset, screenHeight: screenHeight)
            .zIndex(1)

          if let nextPos {
            card(at: nextPos, offset: screenHeight - upDragAmount, screenHeight: screenHeight)
              .opacity(isDragging && dragOffset < 0 ? max(0, upProgress) : 0)
              .zIndex(0)
          }
        }
        .gesture(swipeGesture(screenHeight: screenHeight, totalPositions: totalPositions))
      }
    }
    .ignoresSafeArea(.all)
    .onAppear {
      AccessControl.shared.resetIfNeeded()
      let count = viewModel.totalPositions
      guard count > 0 else {
        viewModel.currentPosition = 0
        viewModel.furthestPosition = 0
        return
      }
      let clampedIndex = min(persistedIndex, count - 1)
      viewModel.currentPosition = clampedIndex
      viewModel.furthestPosition = max(viewModel.furthestPosition, clampedIndex)
    }
    .onChange(of: persistedIndex) { newValue in
      viewModel.currentPosition = min(newValue, max(0, viewModel.totalPositions - 1))
    }
    .onChange(of: viewModel.currentPosition) { newValue in
      persistedIndex = newValue
    }
    .onChange(of: currentDayOfYear) { _ in
      viewModel.currentPosition = 0
      persistedIndex = 0
      viewModel.furthestPosition = 0
      AccessControl.shared.resetIfNeeded()
    }
  }

  // MARK: - Card builder

  @ViewBuilder
  private func card(at position: Int, offset: CGFloat, screenHeight: CGFloat) -> some View {
    if viewModel.isEndCard(at: position) {
      endCard(offset: offset, screenHeight: screenHeight)
    } else if let quote = viewModel.quote(at: position), let rawIndex = viewModel.quoteIndex(at: position) {
      QuoteSlideView(
        quote: quote,
        index: rawIndex,
        isToday: position == 0,
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

  // MARK: - Gesture

  private func swipeGesture(screenHeight: CGFloat, totalPositions: Int) -> some Gesture {
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
        let movedUp = value.translation.height < -dragThreshold
          || value.predictedEndTranslation.height < -dragThreshold
        let movedDown = value.translation.height > dragThreshold
          || value.predictedEndTranslation.height > dragThreshold

        if movedUp {
          handleSwipeUp()
        } else if movedDown {
          handleSwipeDown()
        } else {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = 0
          }
        }

        isDragging = false
      }
  }

  private func handleSwipeUp() {
    let current = viewModel.currentPosition

    if !viewModel.canMoveForward(from: current) {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
        dragOffset = 0
      }
      if !subscriptionManager.isPremiumUser {
        onRequirePaywall()
      } else {
        HapticManager.light()
      }
      return
    }

    let nextPos = current + 1
    if nextPos > viewModel.furthestPosition {
      viewModel.furthestPosition = nextPos
    }

    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      viewModel.currentPosition = nextPos
      dragOffset = 0
    }
    HapticManager.medium()
  }

  private func handleSwipeDown() {
    if viewModel.currentPosition > 0 {
      withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
        viewModel.currentPosition -= 1
        dragOffset = 0
      }
      HapticManager.medium()
    } else {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
        dragOffset = 0
      }
      HapticManager.light()
    }
  }

  private var currentDayOfYear: Int {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())
    return calendar.ordinality(of: .day, in: .year, for: startOfDay) ?? 0
  }
}
