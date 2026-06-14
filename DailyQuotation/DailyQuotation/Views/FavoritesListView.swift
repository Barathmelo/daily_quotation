import SwiftUI

struct FavoritesListView: View {
    @EnvironmentObject private var subscriptionManager: RevenueCatManager
    @ObservedObject var favoritesManager = FavoritesManager.shared
    @Binding var appearance: AppearanceSettings
    /// Signaled by `ContentView` while a horizontal tab-switch drag is
    /// in flight. Mirrored onto the favorites `ScrollView`'s
    /// `.scrollDisabled` so the list can't rubber-band vertically while
    /// the page is being translated sideways.
    @Environment(\.isHorizontalTabSwipeActive) private var isHorizontalTabSwipeActive

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if favoritesManager.favorites.isEmpty {
                    emptyStateView
                } else {
                    scrollView
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: FavoriteEntry.ID.self) { id in
                if let entry = favoritesManager.favorites.first(where: { $0.id == id }) {
                    QuoteDetailView(
                        quote: entry.quote,
                        appearance: entry.appearance,
                        gradientIndex: entry.gradientIndex
                    )
                    .environmentObject(subscriptionManager)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(Color(white: 0.25))

            Text("No Favorites Yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Text("Tap the heart icon on quotes you love\nto save them here.")
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.35))
                .multilineTextAlignment(.center)
        }
    }

    private var scrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("YOUR COLLECTION")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.horizontal, 20)
                    .padding(.top, 80)
                    .padding(.bottom, 4)

                ForEach(favoritesManager.favorites.reversed()) { entry in
                    NavigationLink(value: entry.id) {
                        favoriteCard(entry: entry)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }

                Color.clear.frame(height: 120)
            }
            .readableWidth()
        }
        .scrollDisabled(isHorizontalTabSwipeActive)
    }

    /// One favorite rendered as a compact "mini Feed card": the saved
    /// `theme.background(for: gradientIndex)` fills the entire card, the
    /// snapshot font draws the body, and a soft dark wash keeps text
    /// legible across any palette/photo. Tapping the row navigates to
    /// the detail view (also driven by the snapshot).
    private func favoriteCard(entry: FavoriteEntry) -> some View {
        let cardShape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        return ZStack(alignment: .topTrailing) {
            // Snapshot background — full bleed so each card looks like a
            // miniature of the Feed slide the user originally saved.
            entry.appearance.theme.background(for: entry.gradientIndex)

            // Legibility wash: brighter at top, denser at bottom where
            // the author byline sits.
            LinearGradient(
                colors: [
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.45),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("\"\(entry.quote.text)\"")
                    .font(entry.appearance.font.font(size: entry.appearance.font == .savoye ? 22 : 17))
                    .foregroundColor(.white)
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .truncationMode(.tail)
                    .quoteTextShadow()

                HStack(alignment: .center) {
                    Text(entry.quote.author.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.85))
                        .quoteTextShadow()

                    Spacer()

                    Button {
                        HapticManager.medium()
                        favoritesManager.removeFavorite(entry.quote)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(8)
                            .background(
                                Circle().fill(Color.black.opacity(0.25))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(cardShape)
        .overlay(
            cardShape.stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
    }
}
