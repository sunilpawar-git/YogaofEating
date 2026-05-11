import Foundation

// MARK: - TextContext

enum TextContext {
    case morningThoughts
    case eveningJournal
}

// MARK: - Protocol

protocol TextSignalExtracting {
    func extractSignals(from text: String, context: TextContext) -> [TextSignal]
    func clarityScore(from morningThoughts: String) -> Double
    func sentimentScore(from journalText: String) -> Double
}

// MARK: - Implementation

final class TextSignalExtractor: TextSignalExtracting {
    func extractSignals(from text: String, context _: TextContext) -> [TextSignal] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [.neutral] }

        let lowercased = trimmed.lowercased()
        var signals: [TextSignal] = []

        if self.contains(lowercased, keywords: TextSignalKeywords.grateful) {
            signals.append(.grateful)
        }
        if self.contains(lowercased, keywords: TextSignalKeywords.overwhelmed) {
            signals.append(.overwhelmed)
        } else if self.contains(lowercased, keywords: TextSignalKeywords.stressed) {
            signals.append(.stressed)
        }
        if self.contains(lowercased, keywords: TextSignalKeywords.clear) {
            signals.append(.clear)
        }
        if self.contains(lowercased, keywords: TextSignalKeywords.agentive) {
            signals.append(.agentive)
        }
        if self.contains(lowercased, keywords: TextSignalKeywords.selfCompassionate) {
            signals.append(.selfCompassionate)
        }

        return signals.isEmpty ? [.neutral] : signals
    }

    func clarityScore(from morningThoughts: String) -> Double {
        let signals = self.extractSignals(from: morningThoughts, context: .morningThoughts)
        return self.scoreFromSignals(signals)
    }

    func sentimentScore(from journalText: String) -> Double {
        let signals = self.extractSignals(from: journalText, context: .eveningJournal)
        return self.scoreFromSignals(signals)
    }

    // MARK: - Private

    private func contains(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }

    private func scoreFromSignals(_ signals: [TextSignal]) -> Double {
        guard signals != [.neutral] else { return 0.5 }

        let positiveSignals: Set<TextSignal> = [.clear, .agentive, .selfCompassionate, .grateful]
        let negativeSignals: Set<TextSignal> = [.overwhelmed, .stressed]

        let positiveCount = Double(signals.count(where: { positiveSignals.contains($0) }))
        let negativeCount = Double(signals.count(where: { negativeSignals.contains($0) }))
        let total = positiveCount + negativeCount

        guard total > 0 else { return 0.5 }
        return min(max((positiveCount - negativeCount) / total * 0.5 + 0.5, 0.0), 1.0)
    }
}
