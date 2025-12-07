import Foundation

class GeminiService {
    static let shared = GeminiService()
    
    private let apiKey: String
    
    private init() {
        // 从环境变量或 Info.plist 中读取 API Key
        // 请确保在 Info.plist 或环境中设置 GEMINI_API_KEY
        self.apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
    }
    
    func fetchQuotes(count: Int = 5) async throws -> [Quote] {
        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }
        
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=\(apiKey)")!
        
        let prompt = """
        Generate \(count) unique, inspiring, and thought-provoking quotes.
        The first quote should be particularly relevant for "today" - perhaps about new beginnings, resilience, or mindfulness.
        The subsequent quotes can range from philosophy, success, love, and wisdom.
        Ensure authors are diverse (historical figures, modern thinkers, philosophers).
        Return a JSON array where each quote has: text, author, and category fields.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "text": ["type": "string"],
                            "author": ["type": "string"],
                            "category": ["type": "string"]
                        ],
                        "required": ["text", "author"]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw GeminiError.invalidResponse
            }
            
            let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let candidates = jsonResponse?["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let parts = firstCandidate["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String,
                  let jsonData = text.data(using: .utf8) else {
                throw GeminiError.invalidResponse
            }
            
            let rawQuotes = try JSONDecoder().decode([RawQuote].self, from: jsonData)
            
            return rawQuotes.map { rawQuote in
                Quote(
                    id: UUID().uuidString,
                    text: rawQuote.text,
                    author: rawQuote.author,
                    category: rawQuote.category ?? "Inspiration"
                )
            }
        } catch {
            // 如果 API 调用失败，返回备用名言
            return fallbackQuotes(count: count)
        }
    }
    
    private func fallbackQuotes(count: Int) -> [Quote] {
        let fallbacks = [
            Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs", category: "Success"),
            Quote(text: "Life is what happens when you're busy making other plans.", author: "John Lennon", category: "Life"),
            Quote(text: "It always seems impossible until it's done.", author: "Nelson Mandela", category: "Resilience"),
            Quote(text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt", category: "Dreams"),
            Quote(text: "Be yourself; everyone else is already taken.", author: "Oscar Wilde", category: "Authenticity"),
            Quote(text: "So many books, so little time.", author: "Frank Zappa", category: "Learning"),
            Quote(text: "Two things are infinite: the universe and human stupidity; and I'm not sure about the universe.", author: "Albert Einstein", category: "Wisdom"),
            Quote(text: "Be the change that you wish to see in the world.", author: "Mahatma Gandhi", category: "Change"),
            Quote(text: "In three words I can sum up everything I've learned about life: it goes on.", author: "Robert Frost", category: "Life"),
            Quote(text: "If you tell the truth, you don't have to remember anything.", author: "Mark Twain", category: "Honesty")
        ]
        
        return Array(fallbacks.prefix(count))
    }
}

// MARK: - Helper Types
private struct RawQuote: Codable {
    let text: String
    let author: String
    let category: String?
}

enum GeminiError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API Key is not configured. Please set GEMINI_API_KEY in Info.plist or environment variables."
        case .invalidResponse:
            return "Invalid response from Gemini API."
        }
    }
}


