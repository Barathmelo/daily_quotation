import Foundation

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

struct AppearanceSettings: Codable {
    var font: FontFamily
    var size: TextSize
    
    static let `default` = AppearanceSettings(font: .serif, size: .medium)
}


