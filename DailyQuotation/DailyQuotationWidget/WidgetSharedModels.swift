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
  case serif = "serif"
  case sans = "sans"
  case mono = "mono"

  var displayName: String {
    switch self {
    case .serif: return "Classic"
    case .sans: return "Modern"
    case .mono: return "Type"
    }
  }

  var fontDesign: Font.Design {
    switch self {
    case .serif:
      return .serif
    case .sans:
      return .rounded
    case .mono:
      return .monospaced
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
    .system(size: size.fontSize, design: font.fontDesign)
  }
}
