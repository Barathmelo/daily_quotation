import Foundation
import SwiftUI

/// User-selectable typeface for quote rendering.
///
/// All four are bundled with iOS, no need to ship custom .ttf files.
/// Backed by `Font.custom(_:size:)` using the family/PostScript name.
enum FontFamily: String, Codable, CaseIterable {
    case didot = "didot"
    case futura = "futura"
    case savoye = "savoye"
    case menlo = "menlo"

    /// Short label shown next to the "Aa" preview in the typeface picker.
    var displayName: String {
        switch self {
        case .didot:  return "Editorial"
        case .futura: return "Geometric"
        case .savoye: return "Script"
        case .menlo:  return "Mono"
        }
    }

    /// Family / PostScript name passed to `Font.custom`. iOS resolves
    /// these to system-bundled fonts (no resource registration needed).
    var fontName: String {
        switch self {
        case .didot:  return "Didot"
        case .futura: return "Futura"
        case .savoye: return "Savoye LET"
        case .menlo:  return "Menlo"
        }
    }

    /// Closest `Font.Design` fallback. Used by the Widget which renders
    /// with `.system(size:design:)` for layout simplicity, and by any
    /// place that wants a generic stylistic hint.
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
        case .small:  return 26
        case .medium: return 30
        case .large:  return 40
        }
    }
}

struct AppearanceSettings: Codable {
    var font: FontFamily
    var size: TextSize

    static let `default` = AppearanceSettings(font: .didot, size: .medium)
}
