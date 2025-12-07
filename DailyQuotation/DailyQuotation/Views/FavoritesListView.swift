import SwiftUI

struct FavoritesListView: View {
    @ObservedObject var favoritesManager = FavoritesManager.shared
    @Binding var appearance: AppearanceSettings
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.05)
                .ignoresSafeArea()
            
            if favoritesManager.favorites.isEmpty {
                emptyStateView
            } else {
                scrollView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(white: 0.1))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "heart")
                    .font(.system(size: 32))
                    .foregroundColor(Color(white: 0.3))
            }
            
            Text("No Favorites Yet")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            
            Text("Tap the heart icon on quotes you love to save them here.")
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    private var scrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Collection")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                ForEach(favoritesManager.favorites) { quote in
                    favoriteCard(quote: quote)
                        .padding(.horizontal, 16)
                }
                
                Spacer()
                    .frame(height: 120)
            }
        }
    }
    
    private func favoriteCard(quote: Quote) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "quote.opening")
                .font(.system(size: 24))
                .foregroundColor(Color(white: 0.3))
                .opacity(0.5)
            
            Text("\"\(quote.text)\"")
                .font(fontForAppearance)
                .foregroundColor(Color(white: 0.9))
                .lineSpacing(6)
            
            Divider()
                .background(Color.white.opacity(0.05))
            
            HStack {
                Text(quote.author)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(white: 0.4))
                    .textCase(.uppercase)
                    .tracking(1)
                
                Spacer()
                
                Button(action: {
                    HapticManager.medium()
                    favoritesManager.removeFavorite(quote)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                        .foregroundColor(Color(white: 0.5))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.1).opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    private var fontForAppearance: Font {
        switch appearance.font {
        case .serif:
            return .system(size: 18, design: .serif)
        case .sans:
            return .system(size: 18, design: .rounded)
        case .mono:
            return .system(size: 18, design: .monospaced)
        }
    }
}


