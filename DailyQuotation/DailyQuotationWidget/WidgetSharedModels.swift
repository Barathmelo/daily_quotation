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
  case serif  = "serif"
  case didot  = "didot"
  case futura = "futura"
  case savoye = "savoye"
  case menlo  = "menlo"

  var displayName: String {
    switch self {
    case .serif:  return "Classic"
    case .didot:  return "Editorial"
    case .futura: return "Modern"
    case .savoye: return "Script"
    case .menlo:  return "Mono"
    }
  }

  func font(size: CGFloat) -> Font {
    switch self {
    case .serif:  return .system(size: size, design: .serif)
    case .didot:  return .custom("Didot", size: size)
    case .futura: return .custom("Futura", size: size)
    case .savoye: return .custom("Savoye LET", size: size)
    case .menlo:  return .custom("Menlo", size: size)
    }
  }

  /// Soft `Font.Design` fallback used by widget-side code that
  /// prefers a generic stylistic hint over a named font.
  var fontDesign: Font.Design {
    switch self {
    case .serif:  return .serif
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

  static let `default` = AppearanceSettings(font: .serif, size: .medium)
}

extension AppearanceSettings {
  var quoteFont: Font {
    font.font(size: size.fontSize)
  }
}
