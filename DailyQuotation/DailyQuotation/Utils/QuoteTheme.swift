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

  // Image themes — Scenery
  case mountain
  case oceanPhoto
  case desert
  case forestPhoto

  // Image themes — Universe
  case galaxy
  case milkyway
  case planet
  case starfield

  // Image themes — Abstract
  case glass
  case smoke
  case marble
  case holographic

  var displayName: String {
    switch self {
    case .midnight:    return "Midnight"
    case .sunset:      return "Sunset"
    case .ocean:       return "Ocean"
    case .forest:      return "Forest"
    case .aurora:      return "Aurora"
    case .mono:        return "Mono"
    case .mountain:    return "Mountain"
    case .oceanPhoto:  return "Coast"
    case .desert:      return "Desert"
    case .forestPhoto: return "Woods"
    case .galaxy:      return "Galaxy"
    case .milkyway:    return "Cosmos"
    case .planet:      return "Saturn"
    case .starfield:   return "Stars"
    case .glass:       return "Glass"
    case .smoke:       return "Smoke"
    case .marble:      return "Marble"
    case .holographic: return "Holo"
    }
  }

  // MARK: - Category

  /// User-facing grouping shown in the theme picker. Independent of
  /// `Kind` so future palettes can mix gradients and images inside one
  /// group if it ever makes sense.
  var category: ThemeCategory {
    switch self {
    case .midnight, .sunset, .ocean, .forest, .aurora, .mono:
      return .colors
    case .mountain, .oceanPhoto, .desert, .forestPhoto:
      return .scenery
    case .galaxy, .milkyway, .planet, .starfield:
      return .universe
    case .glass, .smoke, .marble, .holographic:
      return .abstract
    }
  }

  /// All themes that belong to the given category, in declaration order.
  static func themes(in category: ThemeCategory) -> [QuoteTheme] {
    Self.allCases.filter { $0.category == category }
  }

  // MARK: - Kind

  enum Kind {
    /// 5 three-stop palettes; quote index picks one.
    case gradient(colors: [[Color]])
    /// One or more image asset names (image set in Assets.xcassets);
    /// quote index picks one. `isLight: true` applies a heavier dark
    /// overlay so white text stays readable over predominantly bright
    /// backgrounds (e.g. desert, holographic).
    case image(names: [String], isLight: Bool = false)
  }

  var kind: Kind {
    switch self {
    case .midnight:   return .gradient(colors: Gradients.midnight)
    case .sunset:     return .gradient(colors: Gradients.sunset)
    case .ocean:      return .gradient(colors: Gradients.ocean)
    case .forest:     return .gradient(colors: Gradients.forest)
    case .aurora:     return .gradient(colors: Gradients.aurora)
    case .mono:       return .gradient(colors: Gradients.mono)
    case .mountain:    return .image(names: ["theme-mountain-1"])
    case .oceanPhoto:  return .image(names: ["theme-coast-1"])
    case .desert:      return .image(names: ["theme-desert-1"], isLight: true)
    case .forestPhoto: return .image(names: ["theme-forest-1"])
    case .galaxy:      return .image(names: ["theme-galaxy-1"])
    case .milkyway:    return .image(names: ["theme-milkyway-1"])
    case .planet:      return .image(names: ["theme-planet-1"])
    case .starfield:   return .image(names: ["theme-starfield-1"])
    case .glass:       return .image(names: ["theme-glass-1"])
    case .smoke:       return .image(names: ["theme-smoke-1"])
    case .marble:      return .image(names: ["theme-marble-1"])
    case .holographic: return .image(names: ["theme-holographic-1"], isLight: true)
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
    case .image(let names, let isLight):
      let imageName = names[mod(index, names.count)]
      // GeometryReader pins the layout to the parent's size; without it
      // Image(...).resizable().scaledToFill() reports the asset's
      // intrinsic size (1024×1024 etc.) and pushes everything else in
      // the ZStack — including the quote text — off-screen.
      GeometryReader { proxy in
        ZStack {
          // Fallback charcoal underneath in case the asset fails to load.
          Color.black
          Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
          // Darkening overlay: stronger at the bottom where the action
          // buttons sit, lighter at top to preserve image character.
          // Bright photos get a heavier mix so white text remains
          // readable.
          LinearGradient(
            gradient: Gradient(stops: overlayStops(isLight: isLight)),
            startPoint: .top,
            endPoint: .bottom
          )
        }
        .frame(width: proxy.size.width, height: proxy.size.height)
      }
    }
  }

  private func overlayStops(isLight: Bool) -> [Gradient.Stop] {
    if isLight {
      return [
        .init(color: .black.opacity(0.42), location: 0),
        .init(color: .black.opacity(0.58), location: 0.55),
        .init(color: .black.opacity(0.78), location: 1),
      ]
    } else {
      return [
        .init(color: .black.opacity(0.20), location: 0),
        .init(color: .black.opacity(0.40), location: 0.55),
        .init(color: .black.opacity(0.65), location: 1),
      ]
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
    case .image(let names, _):
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

  /// `true` for image themes (used internally and by `previewSwatch`).
  var isImage: Bool {
    if case .image = kind { return true }
    return false
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

// MARK: - Theme category

enum ThemeCategory: String, CaseIterable, Hashable {
  case colors
  case scenery
  case universe
  case abstract

  var displayName: String {
    switch self {
    case .colors:   return "Colors"
    case .scenery:  return "Scenery"
    case .universe: return "Universe"
    case .abstract: return "Abstract"
    }
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
