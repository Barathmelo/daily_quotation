import Combine
import Foundation

class FavoritesManager: ObservableObject {
  static let shared = FavoritesManager()

  private let storageKey = "dailyWisdomFavorites"

  @Published var favorites: [Quote] = []

  private init() {
    loadFavorites()
  }

  func loadFavorites() {
    guard let data = UserDefaults.standard.data(forKey: storageKey),
      let decoded = try? JSONDecoder().decode([Quote].self, from: data)
    else {
      favorites = []
      return
    }
    favorites = decoded
  }

  func saveFavorites() {
    guard let data = try? JSONEncoder().encode(favorites) else { return }
    UserDefaults.standard.set(data, forKey: storageKey)
  }

  func toggleFavorite(_ quote: Quote) {
    if let index = favorites.firstIndex(where: { $0.id == quote.id }) {
      favorites.remove(at: index)
    } else {
      favorites.append(quote)
    }
    saveFavorites()
  }

  func isFavorite(_ quote: Quote) -> Bool {
    favorites.contains(where: { $0.id == quote.id })
  }

  func removeFavorite(_ quote: Quote) {
    favorites.removeAll(where: { $0.id == quote.id })
    saveFavorites()
  }
}
