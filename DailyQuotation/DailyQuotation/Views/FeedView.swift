import SwiftUI

struct FeedView: View {
  @ObservedObject var favoritesManager = FavoritesManager.shared
  @Binding var appearance: AppearanceSettings
  @State private var currentIndex: Int = 0
  @State private var dragOffset: CGFloat = 0
  @State private var isDragging: Bool = false

  private let quotes = LocalQuotes.quotes
  private let screenHeight = UIScreen.main.bounds.height

  var body: some View {
    ZStack {
      // Background
      Color.black.ignoresSafeArea(.all)

      // Quote cards stack
      ZStack {
        // Previous card (always show for infinite loop)
        quoteCard(at: currentIndex - 1, offset: -screenHeight + dragOffset)
          .opacity(isDragging && dragOffset < 0 ? max(0, 0.3 + dragOffset / screenHeight) : 0)
          .zIndex(0)

        // Current card
        quoteCard(at: currentIndex, offset: dragOffset)
          .zIndex(1)

        // Next card (always show for infinite loop)
        quoteCard(at: currentIndex + 1, offset: screenHeight + dragOffset)
          .opacity(isDragging && dragOffset < 0 ? max(0, 0.3 - dragOffset / screenHeight) : 0)
          .zIndex(0)
      }
      .gesture(
        DragGesture(minimumDistance: 20)
          .onChanged { value in
            // Only respond to vertical drags (not horizontal)
            if abs(value.translation.height) > abs(value.translation.width) {
              if !isDragging {
                isDragging = true
                HapticManager.light()
              }

              // Only allow upward dragging
              if value.translation.height < 0 {
                dragOffset = value.translation.height
              }
            }
          }
          .onEnded { value in
            let dragThreshold: CGFloat = screenHeight * 0.25

            if value.translation.height < -dragThreshold
              || abs(value.predictedEndTranslation.height) > dragThreshold
            {
              // Swipe up - go to next quote
              withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentIndex = (currentIndex + 1) % quotes.count
                dragOffset = 0
              }
              HapticManager.medium()
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
  }

  @ViewBuilder
  private func quoteCard(at index: Int, offset: CGFloat) -> some View {
    // Handle negative indices for infinite loop and ensure array is not empty
    if quotes.isEmpty {
      EmptyView()
    } else {
      let actualIndex = ((index % quotes.count) + quotes.count) % quotes.count
      let quote = quotes[actualIndex]

      QuoteSlideView(
        quote: quote,
        index: actualIndex,
        onToggleFavorite: {
          favoritesManager.toggleFavorite(quote)
        },
        appearance: $appearance
      )
      .offset(y: offset)
      .scaleEffect(1.0 - abs(offset) / (screenHeight * 2))
      .opacity(1.0 - abs(offset) / (screenHeight * 1.5))
    }
  }
}
