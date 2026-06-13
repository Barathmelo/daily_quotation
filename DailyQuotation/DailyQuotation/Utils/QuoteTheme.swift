import SwiftUI

/// A complete palette of 5 gradient triplets that drive the look of
/// Feed cards, the share-card poster, the Explore detail view, and the
/// home-screen widget. Each `QuoteTheme` is fully self-contained — the
/// caller picks an index (typically the quote's offset in
/// `LocalQuotes.quotes`) and asks the theme for the matching gradient.
enum QuoteTheme: String, Codable, CaseIterable {
  case midnight
  case sunset
  case ocean
  case forest
  case aurora
  case mono

  var displayName: String {
    switch self {
    case .midnight: return "Midnight"
    case .sunset:   return "Sunset"
    case .ocean:    return "Ocean"
    case .forest:   return "Forest"
    case .aurora:   return "Aurora"
    case .mono:     return "Mono"
    }
  }

  /// Five 3-stop color triplets per theme. Index into this with
  /// `index % colors.count` to pick a deterministic palette per quote.
  var colors: [[Color]] {
    switch self {
    case .midnight:
      return [
        [Color(red: 0.15, green: 0.09, blue: 0.24), Color(red: 0.20, green: 0.09, blue: 0.30), Color(red: 0.08, green: 0.08, blue: 0.12)],
        [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.05, green: 0.20, blue: 0.25), Color(red: 0.03, green: 0.25, blue: 0.20)],
        [Color(red: 0.30, green: 0.05, blue: 0.15), Color(red: 0.30, green: 0.05, blue: 0.10), Color(red: 0.35, green: 0.15, blue: 0.05)],
        [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.10, green: 0.10, blue: 0.12)],
        [Color(red: 0.25, green: 0.20, blue: 0.05), Color(red: 0.30, green: 0.25, blue: 0.05), Color(red: 0.18, green: 0.15, blue: 0.12)],
      ]
    case .sunset:
      return [
        [Color(red: 0.65, green: 0.18, blue: 0.18), Color(red: 0.85, green: 0.30, blue: 0.30), Color(red: 0.40, green: 0.10, blue: 0.30)],
        [Color(red: 0.75, green: 0.35, blue: 0.15), Color(red: 0.85, green: 0.20, blue: 0.30), Color(red: 0.45, green: 0.10, blue: 0.35)],
        [Color(red: 0.55, green: 0.15, blue: 0.20), Color(red: 0.75, green: 0.30, blue: 0.20), Color(red: 0.35, green: 0.08, blue: 0.25)],
        [Color(red: 0.70, green: 0.25, blue: 0.40), Color(red: 0.55, green: 0.15, blue: 0.45), Color(red: 0.30, green: 0.08, blue: 0.30)],
        [Color(red: 0.65, green: 0.30, blue: 0.20), Color(red: 0.55, green: 0.15, blue: 0.35), Color(red: 0.30, green: 0.10, blue: 0.30)],
      ]
    case .ocean:
      return [
        [Color(red: 0.05, green: 0.20, blue: 0.35), Color(red: 0.05, green: 0.30, blue: 0.45), Color(red: 0.05, green: 0.40, blue: 0.40)],
        [Color(red: 0.08, green: 0.18, blue: 0.40), Color(red: 0.05, green: 0.30, blue: 0.50), Color(red: 0.08, green: 0.45, blue: 0.45)],
        [Color(red: 0.04, green: 0.15, blue: 0.30), Color(red: 0.08, green: 0.28, blue: 0.50), Color(red: 0.10, green: 0.40, blue: 0.45)],
        [Color(red: 0.06, green: 0.25, blue: 0.45), Color(red: 0.10, green: 0.40, blue: 0.55), Color(red: 0.15, green: 0.50, blue: 0.45)],
        [Color(red: 0.05, green: 0.20, blue: 0.38), Color(red: 0.08, green: 0.35, blue: 0.48), Color(red: 0.15, green: 0.45, blue: 0.40)],
      ]
    case .forest:
      return [
        [Color(red: 0.05, green: 0.20, blue: 0.10), Color(red: 0.10, green: 0.30, blue: 0.15), Color(red: 0.05, green: 0.15, blue: 0.10)],
        [Color(red: 0.10, green: 0.25, blue: 0.15), Color(red: 0.15, green: 0.32, blue: 0.18), Color(red: 0.08, green: 0.18, blue: 0.10)],
        [Color(red: 0.08, green: 0.18, blue: 0.10), Color(red: 0.18, green: 0.30, blue: 0.15), Color(red: 0.25, green: 0.35, blue: 0.15)],
        [Color(red: 0.10, green: 0.28, blue: 0.20), Color(red: 0.05, green: 0.20, blue: 0.15), Color(red: 0.12, green: 0.22, blue: 0.10)],
        [Color(red: 0.15, green: 0.28, blue: 0.12), Color(red: 0.08, green: 0.20, blue: 0.10), Color(red: 0.05, green: 0.15, blue: 0.08)],
      ]
    case .aurora:
      return [
        [Color(red: 0.10, green: 0.05, blue: 0.30), Color(red: 0.20, green: 0.15, blue: 0.45), Color(red: 0.10, green: 0.45, blue: 0.35)],
        [Color(red: 0.15, green: 0.10, blue: 0.35), Color(red: 0.25, green: 0.40, blue: 0.50), Color(red: 0.10, green: 0.45, blue: 0.30)],
        [Color(red: 0.20, green: 0.08, blue: 0.40), Color(red: 0.10, green: 0.35, blue: 0.50), Color(red: 0.25, green: 0.50, blue: 0.35)],
        [Color(red: 0.05, green: 0.15, blue: 0.30), Color(red: 0.20, green: 0.40, blue: 0.50), Color(red: 0.08, green: 0.40, blue: 0.30)],
        [Color(red: 0.15, green: 0.05, blue: 0.30), Color(red: 0.25, green: 0.30, blue: 0.50), Color(red: 0.15, green: 0.50, blue: 0.40)],
      ]
    case .mono:
      return [
        [Color(red: 0.10, green: 0.10, blue: 0.10), Color(red: 0.20, green: 0.20, blue: 0.20), Color(red: 0.05, green: 0.05, blue: 0.05)],
        [Color(red: 0.15, green: 0.15, blue: 0.15), Color(red: 0.25, green: 0.25, blue: 0.25), Color(red: 0.10, green: 0.10, blue: 0.10)],
        [Color(red: 0.08, green: 0.08, blue: 0.08), Color(red: 0.18, green: 0.18, blue: 0.18), Color(red: 0.03, green: 0.03, blue: 0.03)],
        [Color(red: 0.12, green: 0.12, blue: 0.12), Color(red: 0.22, green: 0.22, blue: 0.22), Color(red: 0.05, green: 0.05, blue: 0.05)],
        [Color(red: 0.20, green: 0.20, blue: 0.20), Color(red: 0.10, green: 0.10, blue: 0.10), Color(red: 0.05, green: 0.05, blue: 0.05)],
      ]
    }
  }

  /// Deterministic gradient for a quote at the given index.
  func gradient(for index: Int) -> LinearGradient {
    let palette = colors[((index % colors.count) + colors.count) % colors.count]
    return LinearGradient(
      gradient: Gradient(colors: palette),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  /// Small swatch gradient for theme-picker buttons.
  var previewGradient: LinearGradient {
    let palette = colors[0]
    return LinearGradient(
      gradient: Gradient(colors: palette),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}
