import Foundation

/// Represents a mindful eating quote for daily inspiration.
struct MindfulQuote: Equatable {
    let text: String
    let author: String?

    /// Formatted quote for display (with or without author attribution)
    var formatted: String {
        if let author = self.author {
            "\"\(self.text)\" — \(author)"
        } else {
            "\"\(self.text)\""
        }
    }

    init(text: String, author: String? = nil) {
        self.text = text
        self.author = author
    }
}
