import CryptoKit
import SwiftUI

enum WidgetSharedDefaults {
  private static let appGroupIdentifier = "group.BiBoBiBo.DailyQuotation"

  static var store: UserDefaults {
    UserDefaults(suiteName: appGroupIdentifier) ?? .standard
  }
}

struct Quote: Identifiable, Codable, Hashable {
  let id: String
  let text: String
  let author: String
  let category: String?

  init(id: String? = nil, text: String, author: String, category: String? = nil) {
    self.id = id ?? Self.stableID(text: text, author: author)
    self.text = text
    self.author = author
    self.category = category
  }

  static func stableID(text: String, author: String) -> String {
    let input = "\(text)|\(author)"
    let digest = SHA256.hash(data: Data(input.utf8))
    return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
  }
}

extension Quote {
  static let placeholder: Quote = Quote(
    id: "widget-placeholder",
    text: "Every moment is a fresh beginning.",
    author: "T.S. Eliot",
    category: "Inspiration"
  )
}

enum FontFamily: String, Codable, CaseIterable {
  case didot = "didot"
  case futura = "futura"
  case savoye = "savoye"
  case menlo = "menlo"

  var displayName: String {
    switch self {
    case .didot:  return "Editorial"
    case .futura: return "Geometric"
    case .savoye: return "Script"
    case .menlo:  return "Mono"
    }
  }

  var fontName: String {
    switch self {
    case .didot:  return "Didot"
    case .futura: return "Futura"
    case .savoye: return "Savoye LET"
    case .menlo:  return "Menlo"
    }
  }

  /// Used by `quoteFont` below as a soft fallback when Font.custom
  /// can't resolve the family in some legacy contexts.
  var fontDesign: Font.Design {
    switch self {
    case .didot:  return .serif
    case .futura: return .default
    case .savoye: return .serif
    case .menlo:  return .monospaced
    }
  }
}

enum TextSize: String, Codable, CaseIterable {
  case small = "sm"
  case medium = "md"
  case large = "lg"

  var fontSize: CGFloat {
    switch self {
    case .small: return 26
    case .medium: return 30
    case .large: return 40
    }
  }
}

struct AppearanceSettings: Codable, Hashable {
  var font: FontFamily
  var size: TextSize

  static let `default` = AppearanceSettings(font: .didot, size: .medium)
}

extension AppearanceSettings {
  var quoteFont: Font {
    .custom(font.fontName, size: size.fontSize)
  }
}
