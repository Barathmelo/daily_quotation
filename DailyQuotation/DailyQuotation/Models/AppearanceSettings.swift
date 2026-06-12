import Foundation
import SwiftUI

/// User-selectable typeface for quote rendering.
///
/// `.serif` is the free-tier default and uses the system SF Serif
/// design (universally available, no Font.custom call). The other
/// four cases map to iOS-bundled fonts loaded via `Font.custom(_:size:)`
/// and are gated behind Premium by `AccessControl.canUseFont`.
enum FontFamily: String, Codable, CaseIterable {
    case serif  = "serif"
    case didot  = "didot"
    case futura = "futura"
    case savoye = "savoye"
    case menlo  = "menlo"

    /// Short label shown next to the "Aa" preview in the typeface picker.
    var displayName: String {
        switch self {
        case .serif:  return "Classic"
        case .didot:  return "Editorial"
        case .futura: return "Geometric"
        case .savoye: return "Script"
        case .menlo:  return "Mono"
        }
    }

    /// Render the typeface at the given size. Encapsulates the
    /// system-vs-custom font branch so callers stay one-liners.
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
    case small  = "sm"
    case medium = "md"
    case large  = "lg"

    var fontSize: CGFloat {
        switch self {
        case .small:  return 26
        case .medium: return 30
        case .large:  return 40
        }
    }
}

struct AppearanceSettings: Codable {
    var font: FontFamily
    var size: TextSize

    static let `default` = AppearanceSettings(font: .serif, size: .medium)
}
