import SwiftUI

/// Read-only feed for a specific historical date.
///
/// Reuses `FeedViewModel(isPremium: true, referenceDate:)` so the rotation
/// matches what the user would have seen on that day. We force
/// `isPremium: true` for the viewmodel because the entry point is already
/// gated behind premium in SettingsSheet; if the user reaches this view
/// they're entitled to see the full 20-quote order.
///
/// Sharing/favorite buttons in QuoteSlideView still resolve their
/// `isPremium` state against the live subscription manager so post-cancel
/// behavior remains correct.
struct HistoryFeedView: View {
  let referenceDate: Date

  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @StateObject private var viewModel: FeedViewModel
  @ObservedObject private var favoritesManager = FavoritesManager.shared
  @StateObject private var appearanceManager = AppearanceManager.shared

  @State private var dragOffset: CGFloat = 0
  @State private var isDragging: Bool = false

  init(referenceDate: Date) {
    self.referenceDate = referenceDate
    self._viewModel = StateObject(
      wrappedValue: FeedViewModel(isPremium: true, referenceDate: referenceDate)
    )
  }

  private var appearanceBinding: Binding<AppearanceSettings> {
    Binding(
      get: { appearanceManager.settings },
      set: { appearanceManager.updateSettings($0) }
    )
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

      ZStack {
        Color.black.ignoresSafeArea()

        ZStack {
          if let prevPos {
            card(at: prevPos, offset: -screenHeight + downDragAmount, screenHeight: screenHeight)
              .opacity(isDragging && dragOffset > 0
                ? min(1, dragOffset / screenHeight)
                : 0)
              .zIndex(0)
          }

          card(at: currentPosition, offset: dragOffset, screenHeight: screenHeight)
            .zIndex(1)

          if let nextPos {
            card(at: nextPos, offset: screenHeight - upDragAmount, screenHeight: screenHeight)
              .opacity(isDragging && dragOffset < 0
                ? min(1, -dragOffset / screenHeight)
                : 0)
              .zIndex(0)
          }
        }
        .gesture(swipeGesture(screenHeight: screenHeight))
      }
    }
    .ignoresSafeArea()
    .navigationTitle(referenceDate.formatted(date: .abbreviated, time: .omitted))
    .navigationBarTitleDisplayMode(.inline)
    .toolbarColorScheme(.dark, for: .navigationBar)
  }

  @ViewBuilder
  private func card(at position: Int, offset: CGFloat, screenHeight: CGFloat) -> some View {
    if let quote = viewModel.quote(at: position),
       let rawIndex = viewModel.quoteIndex(at: position) {
      QuoteSlideView(
        quote: quote,
        index: rawIndex,
        isToday: false,
        isPremium: subscriptionManager.isPremiumUser,
        onRequirePaywall: {},
        onToggleFavorite: {
          favoritesManager.toggleFavorite(quote)
        },
        appearance: appearanceBinding
      )
      .offset(y: offset)
      .scaleEffect(1.0 - abs(offset) / (screenHeight * 2))
      .opacity(1.0 - abs(offset) / (screenHeight * 1.5))
    }
  }

  private func swipeGesture(screenHeight: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 20)
      .onChanged { value in
        if abs(value.translation.height) > abs(value.translation.width) {
          isDragging = true
          dragOffset = value.translation.height
        }
      }
      .onEnded { value in
        let threshold = screenHeight * 0.25
        let movedUp = value.translation.height < -threshold
          || value.predictedEndTranslation.height < -threshold
        let movedDown = value.translation.height > threshold
          || value.predictedEndTranslation.height > threshold

        if movedUp, viewModel.canMoveForward(from: viewModel.currentPosition) {
          withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            viewModel.currentPosition += 1
            dragOffset = 0
          }
          HapticManager.medium()
        } else if movedDown, viewModel.currentPosition > 0 {
          withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            viewModel.currentPosition -= 1
            dragOffset = 0
          }
          HapticManager.medium()
        } else {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = 0
          }
        }
        isDragging = false
      }
  }
}
