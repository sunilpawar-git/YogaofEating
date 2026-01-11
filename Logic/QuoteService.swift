import Foundation

/// Service to provide daily rotating mindful eating quotes.
/// Loads quotes from JSON file with fallback to hardcoded defaults.
enum QuoteService {
    /// JSON structure for decoding quotes file
    private struct QuotesFile: Codable {
        let quotes: [QuoteEntry]
    }

    private struct QuoteEntry: Codable {
        let text: String
        let author: String?
    }

    /// Collection of mindful eating quotes (loaded from JSON or fallback)
    static let quotes: [MindfulQuote] = Self.loadQuotes()

    /// Loads quotes from JSON file, falls back to hardcoded defaults if loading fails
    private static func loadQuotes() -> [MindfulQuote] {
        // Try to load from JSON file
        if let url = Bundle.main.url(forResource: "mindful_quotes", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let quotesFile = try? JSONDecoder().decode(QuotesFile.self, from: data)
        {
            return quotesFile.quotes.map { MindfulQuote(text: $0.text, author: $0.author) }
        }

        // Fallback to hardcoded quotes if JSON loading fails
        return Self.fallbackQuotes
    }

    /// Fallback quotes if JSON file cannot be loaded
    private static let fallbackQuotes: [MindfulQuote] = [
        MindfulQuote(text: "Eat with awareness, not on autopilot", author: nil),
        MindfulQuote(text: "Your body knows what it needs", author: nil),
        MindfulQuote(text: "Slow down and taste your food", author: nil),
        MindfulQuote(text: "Hunger is not an emergency", author: nil),
        MindfulQuote(text: "Every bite is a choice", author: nil),
        MindfulQuote(text: "Listen to your body's wisdom", author: nil),
        MindfulQuote(text: "Eat when hungry, stop when satisfied", author: nil),
        MindfulQuote(text: "Food is information for your cells", author: nil),
        MindfulQuote(text: "Nourish yourself with intention", author: nil),
        MindfulQuote(text: "Quality over quantity", author: nil),
        MindfulQuote(text: "Chew your food mindfully", author: nil),
        MindfulQuote(text: "Gratitude transforms meals", author: nil),
        MindfulQuote(text: "Your fork is a powerful tool", author: nil),
        MindfulQuote(text: "Eating is a sacred act", author: nil),
        MindfulQuote(text: "Pause before each bite", author: nil),
        MindfulQuote(text: "Food is neither good nor bad", author: nil),
        MindfulQuote(text: "Trust your inner guide", author: nil),
        MindfulQuote(text: "Eating slowly prevents overeating", author: nil),
        MindfulQuote(text: "Notice textures, flavors, aromas", author: nil),
        MindfulQuote(text: "Your body is your temple", author: nil),
        MindfulQuote(text: "Eat with all your senses", author: nil),
        MindfulQuote(text: "Balance is found through awareness", author: nil),
        MindfulQuote(text: "Mindful eating is self-care", author: nil),
        MindfulQuote(text: "Put down your phone, pick up awareness", author: nil),
        MindfulQuote(text: "Each meal is a fresh start", author: nil),
        MindfulQuote(text: "Honor your hunger and fullness", author: nil),
        MindfulQuote(text: "Food is fuel and pleasure", author: nil),
        MindfulQuote(text: "Breathe between bites", author: nil),
        MindfulQuote(text: "Satisfaction comes from attention", author: nil),
        MindfulQuote(text: "Your relationship with food matters", author: nil)
    ]

    /// Returns the quote for a specific date (cycles through quotes based on day of year)
    /// - Parameter date: The date to get the quote for (defaults to today)
    /// - Returns: The mindful eating quote for that day
    static func getDailyQuote(for date: Date = Date()) -> MindfulQuote {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let quoteCount = self.quotes.isEmpty ? 1 : self.quotes.count
        let index = (dayOfYear - 1) % quoteCount
        return self.quotes.isEmpty
            ? MindfulQuote(text: "Eat mindfully", author: nil)
            : self.quotes[index]
    }
}
