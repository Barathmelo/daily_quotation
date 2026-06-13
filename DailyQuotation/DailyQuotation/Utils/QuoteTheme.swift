import SwiftUI

/// Visual treatment for the background of a quote card. Two kinds:
///
/// - `.gradient` — pure 3-stop linear gradients (the original look).
/// - `.image` — bundled image assets with a darkening overlay so the
///   quote text stays legible regardless of the underlying photo.
///
/// Themes that ship multiple palettes / images (`colors.count > 1` or
/// `imageNames.count > 1`) rotate them per quote via
/// `index % count`, mirroring how Feed picks a different gradient
/// per slide so adjacent cards look distinct.
enum QuoteTheme: String, Codable, CaseIterable {
  // Gradient themes (existing)
  case midnight
  case sunset
  case ocean
  case forest
  case aurora
  case mono

  // Image themes (new)
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

  // MARK: - Kind

  enum Kind {
    /// 5 three-stop palettes; quote index picks one.
    case gradient(colors: [[Color]])
    /// One or more image asset names (image set in Assets.xcassets);
    /// quote index picks one.
    case image(names: [String])
  }

  var kind: Kind {
    switch self {
    case .midnight:   return .gradient(colors: Gradients.midnight)
    case .sunset:     return .gradient(colors: Gradients.sunset)
    case .ocean:      return .gradient(colors: Gradients.ocean)
    case .forest:     return .gradient(colors: Gradients.forest)
    case .aurora:     return .gradient(colors: Gradients.aurora)
    case .mono:       return .gradient(colors: Gradients.mono)
    case .mountain:   return .image(names: ["theme-mountain-1", "theme-mountain-2"])
    case .oceanPhoto: return .image(names: ["theme-coast-1", "theme-coast-2"])
    case .galaxy:     return .image(names: ["theme-galaxy-1", "theme-galaxy-2"])
    case .glass:      return .image(names: ["theme-glass-1", "theme-glass-2"])
    }
  }

  /// Whether the picker swatch should be rendered as a gradient ring
  /// or as a clipped image preview.
  var isImageTheme: Bool {
    if case .image = kind { return true }
    return false
  }

  // MARK: - Rendering

  /// Background view for a Feed / Detail / Share card. For gradient
  /// themes this is a `LinearGradient`; for image themes it's an
  /// `Image` with a darkening overlay so the quote text remains
  /// legible across any photo.
  @ViewBuilder
  func background(for index: Int) -> some View {
    switch kind {
    case .gradient(let palettes):
      let palette = palettes[mod(index, palettes.count)]
      LinearGradient(
        gradient: Gradient(colors: palette),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .image(let names):
      let imageName = names[mod(index, names.count)]
      ZStack {
        // Fallback charcoal underneath in case the asset fails to load.
        Color.black
        Image(imageName)
          .resizable()
          .scaledToFill()
        // Darkening overlay: stronger at the bottom where the action
        // buttons sit, lighter at top to preserve image character.
        LinearGradient(
          gradient: Gradient(stops: [
            .init(color: .black.opacity(0.20), location: 0),
            .init(color: .black.opacity(0.40), location: 0.55),
            .init(color: .black.opacity(0.65), location: 1),
          ]),
          startPoint: .top,
          endPoint: .bottom
        )
      }
    }
  }

  /// Compact preview used inside the theme picker. Image themes get a
  /// circular clipped photo; gradient themes get the existing gradient
  /// ring.
  @ViewBuilder
  func previewSwatch(size: CGFloat) -> some View {
    switch kind {
    case .gradient(let palettes):
      LinearGradient(
        gradient: Gradient(colors: palettes[0]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .frame(width: size, height: size)
      .clipShape(Circle())
    case .image(let names):
      Image(names[0])
        .resizable()
        .scaledToFill()
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
  }

  // MARK: - Helpers

  private func mod(_ value: Int, _ modulus: Int) -> Int {
    let m = max(1, modulus)
    return ((value % m) + m) % m
  }

  // MARK: - Back-compat shims

  /// Legacy API: only meaningful for gradient themes. Returns the
  /// first palette as a flat color list (image themes return `[]`).
  /// Used by `GradientColors.gradients.count` calculations that
  /// pre-date themes.
  var colors: [[Color]] {
    switch kind {
    case .gradient(let palettes): return palettes
    case .image:                  return []
    }
  }

  func gradient(for index: Int) -> LinearGradient {
    switch kind {
    case .gradient(let palettes):
      let palette = palettes[mod(index, palettes.count)]
      return LinearGradient(
        gradient: Gradient(colors: palette),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .image:
      // For image themes there's no meaningful gradient, but some
      // legacy call sites still ask for one. Fall back to Midnight.
      return QuoteTheme.midnight.gradient(for: index)
    }
  }

  var previewGradient: LinearGradient {
    if case .gradient(let palettes) = kind {
      return LinearGradient(
        gradient: Gradient(colors: palettes[0]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
    return QuoteTheme.midnight.previewGradient
  }
}

// MARK: - Palette tables

private enum Gradients {
  static let midnight: [[Color]] = [
    [Color(red: 0.15, green: 0.09, blue: 0.24), Color(red: 0.20, green: 0.09, blue: 0.30), Color(red: 0.08, green: 0.08, blue: 0.12)],
    [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.05, green: 0.20, blue: 0.25), Color(red: 0.03, green: 0.25, blue: 0.20)],
    [Color(red: 0.30, green: 0.05, blue: 0.15), Color(red: 0.30, green: 0.05, blue: 0.10), Color(red: 0.35, green: 0.15, blue: 0.05)],
    [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.10, green: 0.10, blue: 0.12)],
    [Color(red: 0.25, green: 0.20, blue: 0.05), Color(red: 0.30, green: 0.25, blue: 0.05), Color(red: 0.18, green: 0.15, blue: 0.12)],
  ]

  static let sunset: [[Color]] = [
    [Color(red: 0.65, green: 0.18, blue: 0.18), Color(red: 0.85, green: 0.30, blue: 0.30), Color(red: 0.40, green: 0.10, blue: 0.30)],
    [Color(red: 0.75, green: 0.35, blue: 0.15), Color(red: 0.85, green: 0.20, blue: 0.30), Color(red: 0.45, green: 0.10, blue: 0.35)],
    [Color(red: 0.55, green: 0.15, blue: 0.20), Color(red: 0.75, green: 0.30, blue: 0.20), Color(red: 0.35, green: 0.08, blue: 0.25)],
    [Color(red: 0.70, green: 0.25, blue: 0.40), Color(red: 0.55, green: 0.15, blue: 0.45), Color(red: 0.30, green: 0.08, blue: 0.30)],
    [Color(red: 0.65, green: 0.30, blue: 0.20), Color(red: 0.55, green: 0.15, blue: 0.35), Color(red: 0.30, green: 0.10, blue: 0.30)],
  ]

  static let ocean: [[Color]] = [
    [Color(red: 0.05, green: 0.20, blue: 0.35), Color(red: 0.05, green: 0.30, blue: 0.45), Color(red: 0.05, green: 0.40, blue: 0.40)],
    [Color(red: 0.08, green: 0.18, blue: 0.40), Color(red: 0.05, green: 0.30, blue: 0.50), Color(red: 0.08, green: 0.45, blue: 0.45)],
    [Color(red: 0.04, green: 0.15, blue: 0.30), Color(red: 0.08, green: 0.28, blue: 0.50), Color(red: 0.10, green: 0.40, blue: 0.45)],
    [Color(red: 0.06, green: 0.25, blue: 0.45), Color(red: 0.10, green: 0.40, blue: 0.55), Color(red: 0.15, green: 0.50, blue: 0.45)],
    [Color(red: 0.05, green: 0.20, blue: 0.38), Color(red: 0.08, green: 0.35, blue: 0.48), Color(red: 0.15, green: 0.45, blue: 0.40)],
  ]

  static let forest: [[Color]] = [
    [Color(red: 0.05, green: 0.20, blue: 0.10), Color(red: 0.10, green: 0.30, blue: 0.15), Color(red: 0.05, green: 0.15, blue: 0.10)],
    [Color(red: 0.10, green: 0.25, blue: 0.15), Color(red: 0.15, green: 0.32, blue: 0.18), Color(red: 0.08, green: 0.18, blue: 0.10)],
    [Color(red: 0.08, green: 0.18, blue: 0.10), Color(red: 0.18, green: 0.30, blue: 0.15), Color(red: 0.25, green: 0.35, blue: 0.15)],
    [Color(red: 0.10, green: 0.28, blue: 0.20), Color(red: 0.05, green: 0.20, blue: 0.15), Color(red: 0.12, green: 0.22, blue: 0.10)],
    [Color(red: 0.15, green: 0.28, blue: 0.12), Color(red: 0.08, green: 0.20, blue: 0.10), Color(red: 0.05, green: 0.15, blue: 0.08)],
  ]

  static let aurora: [[Color]] = [
    [Color(red: 0.10, green: 0.05, blue: 0.30), Color(red: 0.20, green: 0.15, blue: 0.45), Color(red: 0.10, green: 0.45, blue: 0.35)],
    [Color(red: 0.15, green: 0.10, blue: 0.35), Color(red: 0.25, green: 0.40, blue: 0.50), Color(red: 0.10, green: 0.45, blue: 0.30)],
    [Color(red: 0.20, green: 0.08, blue: 0.40), Color(red: 0.10, green: 0.35, blue: 0.50), Color(red: 0.25, green: 0.50, blue: 0.35)],
    [Color(red: 0.05, green: 0.15, blue: 0.30), Color(red: 0.20, green: 0.40, blue: 0.50), Color(red: 0.08, green: 0.40, blue: 0.30)],
    [Color(red: 0.15, green: 0.05, blue: 0.30), Color(red: 0.25, green: 0.30, blue: 0.50), Color(red: 0.15, green: 0.50, blue: 0.40)],
  ]

  static let mono: [[Color]] = [
    [Color(red: 0.10, green: 0.10, blue: 0.10), Color(red: 0.20, green: 0.20, blue: 0.20), Color(red: 0.05, green: 0.05, blue: 0.05)],
    [Color(red: 0.15, green: 0.15, blue: 0.15), Color(red: 0.25, green: 0.25, blue: 0.25), Color(red: 0.10, green: 0.10, blue: 0.10)],
    [Color(red: 0.08, green: 0.08, blue: 0.08), Color(red: 0.18, green: 0.18, blue: 0.18), Color(red: 0.03, green: 0.03, blue: 0.03)],
    [Color(red: 0.12, green: 0.12, blue: 0.12), Color(red: 0.22, green: 0.22, blue: 0.22), Color(red: 0.05, green: 0.05, blue: 0.05)],
    [Color(red: 0.20, green: 0.20, blue: 0.20), Color(red: 0.10, green: 0.10, blue: 0.10), Color(red: 0.05, green: 0.05, blue: 0.05)],
  ]
}
