import CryptoKit
import Foundation

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

    /// Deterministic identifier derived from the quote's content so that
    /// re-decoding `quotes.json` (or any persistence round-trip) preserves
    /// favorite/identity matching across launches.
    static func stableID(text: String, author: String) -> String {
        let input = "\(text)|\(author)"
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Initial Quote
extension Quote {
    static let initial: Quote = Quote(
        id: "initial-1",
        text: "Every moment is a fresh beginning.",
        author: "T.S. Eliot",
        category: "Inspiration"
    )
}


