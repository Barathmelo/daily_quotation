import Foundation
import SwiftUI

struct LocalQuotes {
    static let quotes: [Quote] = {
        if let loaded = loadQuotesFromAsset(), !loaded.isEmpty {
            return loaded
        }
        return fallbackQuotes
    }()
    
    static func getQuotes(count: Int? = nil) -> [Quote] {
        if let count = count {
            return Array(quotes.prefix(count))
        }
        return quotes
    }
    
    // 支持无限循环：获取指定索引的名言（循环）
    static func getQuote(at index: Int) -> Quote {
        return quotes[index % quotes.count]
    }
}

// MARK: - Loading
private extension LocalQuotes {
    static func loadQuotesFromAsset() -> [Quote]? {
        guard let dataAsset = NSDataAsset(name: "quotes") else {
            return nil
        }
        
        do {
            let records = try JSONDecoder().decode([QuoteRecord].self, from: dataAsset.data)
            let mapped = records.compactMap { $0.toQuote() }
            return mapped.isEmpty ? nil : mapped
        } catch {
            print("Failed to decode quotes.json: \(error)")
            return nil
        }
    }
    
    static func normalizedCategory(from record: QuoteRecord) -> String? {
        if let explicit = cleaned(record.category) {
            return formatted(category: explicit)
        }
        
        guard let tags = record.tags else { return nil }
        for tag in tags {
            guard let cleanedTag = cleaned(tag) else { continue }
            if cleanedTag.contains("-") || cleanedTag.contains("_") { continue }
            return formatted(category: cleanedTag)
        }
        return nil
    }
    
    static func cleaned(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
    
    static func formatted(category: String) -> String {
        category.capitalized
    }
    
    struct QuoteRecord: Decodable {
        let quote: String
        let author: String
        let tags: [String]?
        let category: String?
        
        enum CodingKeys: String, CodingKey {
            case quote = "Quote"
            case author = "Author"
            case tags = "Tags"
            case category = "Category"
        }
        
        func toQuote() -> Quote? {
            let trimmedQuote = quote.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedQuote.isEmpty, !trimmedAuthor.isEmpty else { return nil }
            
            let categoryValue = LocalQuotes.normalizedCategory(from: self)
            return Quote(
                id: UUID().uuidString,
                text: trimmedQuote,
                author: trimmedAuthor,
                category: categoryValue
            )
        }
    }
    
    static let fallbackQuotes: [Quote] = [
        Quote(
            id: "local-1",
            text: "Every moment is a fresh beginning.",
            author: "T.S. Eliot",
            category: "Inspiration"
        ),
        Quote(
            id: "local-2",
            text: "The only way to do great work is to love what you do.",
            author: "Steve Jobs",
            category: "Success"
        ),
        Quote(
            id: "local-3",
            text: "Life is what happens when you're busy making other plans.",
            author: "John Lennon",
            category: "Life"
        ),
        Quote(
            id: "local-4",
            text: "It always seems impossible until it's done.",
            author: "Nelson Mandela",
            category: "Resilience"
        ),
        Quote(
            id: "local-5",
            text: "The future belongs to those who believe in the beauty of their dreams.",
            author: "Eleanor Roosevelt",
            category: "Dreams"
        ),
        Quote(
            id: "local-6",
            text: "Be yourself; everyone else is already taken.",
            author: "Oscar Wilde",
            category: "Authenticity"
        ),
        Quote(
            id: "local-7",
            text: "So many books, so little time.",
            author: "Frank Zappa",
            category: "Learning"
        ),
        Quote(
            id: "local-8",
            text: "Be the change that you wish to see in the world.",
            author: "Mahatma Gandhi",
            category: "Change"
        ),
        Quote(
            id: "local-9",
            text: "In three words I can sum up everything I've learned about life: it goes on.",
            author: "Robert Frost",
            category: "Life"
        ),
        Quote(
            id: "local-10",
            text: "If you tell the truth, you don't have to remember anything.",
            author: "Mark Twain",
            category: "Honesty"
        ),
        Quote(
            id: "local-11",
            text: "Two roads diverged in a wood, and I took the one less traveled by, and that has made all the difference.",
            author: "Robert Frost",
            category: "Choices"
        ),
        Quote(
            id: "local-12",
            text: "The only impossible journey is the one you never begin.",
            author: "Tony Robbins",
            category: "Motivation"
        ),
        Quote(
            id: "local-13",
            text: "Success is not final, failure is not fatal: it is the courage to continue that counts.",
            author: "Winston Churchill",
            category: "Perseverance"
        ),
        Quote(
            id: "local-14",
            text: "The way to get started is to quit talking and begin doing.",
            author: "Walt Disney",
            category: "Action"
        ),
        Quote(
            id: "local-15",
            text: "Don't be afraid to give up the good to go for the great.",
            author: "John D. Rockefeller",
            category: "Ambition"
        ),
        Quote(
            id: "local-16",
            text: "Innovation distinguishes between a leader and a follower.",
            author: "Steve Jobs",
            category: "Innovation"
        ),
        Quote(
            id: "local-17",
            text: "The greatest glory in living lies not in never falling, but in rising every time we fall.",
            author: "Nelson Mandela",
            category: "Resilience"
        ),
        Quote(
            id: "local-18",
            text: "Your time is limited, don't waste it living someone else's life.",
            author: "Steve Jobs",
            category: "Authenticity"
        ),
        Quote(
            id: "local-19",
            text: "The only person you are destined to become is the person you decide to be.",
            author: "Ralph Waldo Emerson",
            category: "Self-Determination"
        ),
        Quote(
            id: "local-20",
            text: "Go confidently in the direction of your dreams. Live the life you have imagined.",
            author: "Henry David Thoreau",
            category: "Dreams"
        )
    ]
}

