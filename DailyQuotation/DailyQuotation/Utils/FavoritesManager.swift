import Combine
import Foundation

/// A single saved favorite, packaged with a snapshot of the appearance
/// settings (font / size / theme) and gradient index that were active
/// at the moment the user tapped the heart. Snapshotting lets the
/// Favorites tab show every saved card with the exact visual it had
/// when collected — even if the user later switches the global theme.
struct FavoriteEntry: Identifiable, Codable {
  let quote: Quote
  let appearance: AppearanceSettings
  let gradientIndex: Int

  var id: String { quote.id }
}

class FavoritesManager: ObservableObject {
  static let shared = FavoritesManager()

  private let storageKey = "dailyWisdomFavorites"

  @Published var favorites: [FavoriteEntry] = []

  private init() {
    loadFavorites()
  }

  func loadFavorites() {
    guard let data = SharedDefaults.store.data(forKey: storageKey),
      let decoded = try? JSONDecoder().decode([FavoriteEntry].self, from: data)
    else {
      favorites = []
      return
    }
    favorites = decoded
  }

  func saveFavorites() {
    guard let data = try? JSONEncoder().encode(favorites) else { return }
    SharedDefaults.store.set(data, forKey: storageKey)
  }

  /// Toggle membership, snapshotting `appearance` + `gradientIndex` when
  /// adding so the Favorites tab can later re-render the card exactly
  /// as it looked at save time.
  func toggleFavorite(_ quote: Quote, appearance: AppearanceSettings, gradientIndex: Int) {
    if let index = favorites.firstIndex(where: { $0.quote.id == quote.id }) {
      favorites.remove(at: index)
    } else {
      favorites.append(
        FavoriteEntry(
          quote: quote,
          appearance: appearance,
          gradientIndex: gradientIndex
        )
      )
    }
    saveFavorites()
  }

  func isFavorite(_ quote: Quote) -> Bool {
    favorites.contains(where: { $0.quote.id == quote.id })
  }

  func removeFavorite(_ quote: Quote) {
    favorites.removeAll(where: { $0.quote.id == quote.id })
    saveFavorites()
  }
}
