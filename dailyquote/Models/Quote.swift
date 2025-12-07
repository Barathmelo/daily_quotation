import Foundation

struct Quote: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let author: String
    let category: String?
    
    init(id: String = UUID().uuidString, text: String, author: String, category: String? = nil) {
        self.id = id
        self.text = text
        self.author = author
        self.category = category
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


