import SwiftUI

/// Widget-side copy of `QuoteTheme`. Kept in sync manually with the
/// main-app version (M1 design deferred unifying these models).
///
/// Widget always renders the gradient form even for "image" themes —
/// home-screen widgets don't bundle the photo assets to keep the
/// extension's binary small, so we fall back to Midnight gradient for
/// image themes. The Feed/Detail/Share surfaces inside the app still
/// show the full image background.
enum QuoteTheme: String, Codable, CaseIterable {
  // Gradient themes
  case midnight
  case sunset
  case ocean
  case forest
  case aurora
  case mono
  // Image themes (rendered as Midnight gradient on widget — see above)
  case mountain
  case oceanPhoto
  case galaxy
  case glass

  var displayName: String {
    switch self {
    case .midnight:   return "Midnight"
    case .sunset:     return "Sunset"
    case .ocean:      return "Ocean"
    case .forest:     return "Forest"
    case .aurora:     return "Aurora"
    case .mono:       return "Mono"
    case .mountain:   return "Mountain"
    case .oceanPhoto: return "Coast"
    case .galaxy:     return "Galaxy"
    case .glass:      return "Glass"
    }
  }

  /// 5 three-stop gradient palettes; image themes resolve to Midnight.
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
    case .mountain, .oceanPhoto, .galaxy, .glass:
      // Fallback to Midnight in widget contexts (no image assets bundled
      // in the extension).
      return QuoteTheme.midnight.colors
    }
  }

  func gradient(for index: Int) -> LinearGradient {
    let palette = colors[((index % colors.count) + colors.count) % colors.count]
    return LinearGradient(
      gradient: Gradient(colors: palette),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  var previewGradient: LinearGradient {
    LinearGradient(
      gradient: Gradient(colors: colors[0]),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}
