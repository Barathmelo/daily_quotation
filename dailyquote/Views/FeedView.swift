import SwiftUI

struct FeedView: View {
    @ObservedObject var favoritesManager = FavoritesManager.shared
    @Binding var quotes: [Quote]
    @Binding var isLoading: Bool
    @Binding var appearance: AppearanceSettings
    let onRefresh: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading && quotes.isEmpty {
                loadingView
            } else {
                scrollView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Curating Wisdom...")
                .font(.system(size: 12, weight: .medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
        }
    }
    
    private var scrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(quotes.enumerated()), id: \.element.id) { index, quote in
                        QuoteSlideView(
                            quote: quote,
                            index: index,
                            onToggleFavorite: {
                                favoritesManager.toggleFavorite(quote)
                            },
                            appearance: $appearance
                        )
                        .frame(height: UIScreen.main.bounds.height)
                        .id(quote.id)
                    }
                    
                    // End of feed
                    endOfFeedView
                        .frame(height: UIScreen.main.bounds.height)
                }
            }
        }
    }
    
    private var endOfFeedView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 8) {
                Text("That's it for now.")
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("You've reached the end of this collection.\nReady for more inspiration?")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Button(action: {
                HapticManager.medium()
                onRefresh()
            }) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .semibold))
                            .rotationEffect(.degrees(isLoading ? 180 : 0))
                            .animation(.easeInOut(duration: 0.5), value: isLoading)
                    }
                    
                    Text("Load Fresh Quotes")
                        .font(.system(size: 16, weight: .semibold))
                        .tracking(1)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .disabled(isLoading)
            }
            
            Spacer()
                .frame(height: 120)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.05, green: 0.05, blue: 0.05))
    }
}

