import Foundation

enum InputValidator {
    // MARK: - Length Constants (Reference ValidationLimits SSOT)

    static let mealDescriptionMaxLength = ValidationLimits.mealDescription
    static let journalEntryMaxLength = ValidationLimits.journalEntry
    static let sleepNotesMaxLength = ValidationLimits.sleepNotes
    static let morningThoughtsMaxLength = ValidationLimits.morningThoughts
    static let todoItemMaxLength = ValidationLimits.todoItem

    // MARK: - Suspicious Patterns (SSOT)

    private static let sqlInjectionPatterns = [
        "DROP TABLE",
        "DELETE FROM",
        "INSERT INTO",
        "UPDATE SET",
        "UNION SELECT"
    ]

    private static let commandInjectionPatterns = [
        "$(", "${", "#!/", "`"
    ]

    private static let xssPatterns = [
        // Dangerous HTML tags that could execute code
        "<SCRIPT",
        "</SCRIPT",
        "<IMG",
        "<IFRAME",
        "<EMBED",
        "<OBJECT",
        "<SVG",
        "<LINK",
        "<STYLE",
        // JavaScript protocol and event handlers
        "JAVASCRIPT:",
        "ONERROR=",
        "ONLOAD=",
        "ONCLICK=",
        "ONMOUSEOVER=",
        "ONFOCUS=",
        "ONBLUR=",
        "ONCHANGE=",
        "ONSUBMIT=",
        "ONDBLCLICK="
    ]

    private static let codeExecutionPatterns = [
        "EVAL",
        "EXEC",
        "SYSTEM"
    ]

    // MARK: - Validation Functions

    static func validateMealDescription(_ text: String) -> Result<String, ValidationError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.empty("Meal description cannot be empty"))
        }

        guard trimmed.count <= self.mealDescriptionMaxLength else {
            return .failure(.exceededLength(
                "Meal description exceeds \(self.mealDescriptionMaxLength) characters"
            ))
        }

        guard !self.containsSuspiciousPatterns(trimmed) else {
            return .failure(.suspiciousContent("Meal description contains invalid characters"))
        }

        let sanitized = self.removeDangerousCharacters(trimmed)
        return .success(sanitized)
    }

    static func validateJournalEntry(_ text: String) -> Result<String, ValidationError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.empty("Journal entry cannot be empty"))
        }

        guard trimmed.count <= self.journalEntryMaxLength else {
            return .failure(.exceededLength(
                "Journal entry exceeds \(self.journalEntryMaxLength) characters"
            ))
        }

        guard !self.containsSuspiciousPatterns(trimmed) else {
            return .failure(.suspiciousContent("Journal entry contains invalid characters"))
        }

        let sanitized = self.removeDangerousCharacters(trimmed)
        return .success(sanitized)
    }

    static func validateSleepNotes(_ text: String) -> Result<String, ValidationError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count <= self.sleepNotesMaxLength else {
            return .failure(.exceededLength(
                "Sleep notes exceed \(self.sleepNotesMaxLength) characters"
            ))
        }

        if trimmed.isEmpty {
            return .success("")
        }

        guard !self.containsSuspiciousPatterns(trimmed) else {
            return .failure(.suspiciousContent("Sleep notes contain invalid characters"))
        }

        let sanitized = self.removeDangerousCharacters(trimmed)
        return .success(sanitized)
    }

    static func validateMorningThoughts(_ text: String) -> Result<String, ValidationError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count <= self.morningThoughtsMaxLength else {
            return .failure(.exceededLength(
                "Morning thoughts exceed \(self.morningThoughtsMaxLength) characters"
            ))
        }

        if trimmed.isEmpty {
            return .success("")
        }

        guard !self.containsSuspiciousPatterns(trimmed) else {
            return .failure(.suspiciousContent("Morning thoughts contain invalid characters"))
        }

        let sanitized = self.removeDangerousCharacters(trimmed)
        return .success(sanitized)
    }

    static func validateTodoItem(_ text: String) -> Result<String, ValidationError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.empty("To-do cannot be empty"))
        }

        guard trimmed.count <= self.todoItemMaxLength else {
            return .failure(.exceededLength(
                "To-do exceeds \(self.todoItemMaxLength) characters"
            ))
        }

        guard !self.containsSuspiciousPatterns(trimmed) else {
            return .failure(.suspiciousContent("To-do contains invalid characters"))
        }

        let sanitized = self.removeDangerousCharacters(trimmed)
        return .success(sanitized)
    }

    // MARK: - Private Helpers

    private static func containsSuspiciousPatterns(_ text: String) -> Bool {
        let upperText = text.uppercased()

        for pattern in self.sqlInjectionPatterns {
            if upperText.contains(pattern) { return true }
        }

        for pattern in self.commandInjectionPatterns {
            if text.contains(pattern) { return true }
        }

        for pattern in self.xssPatterns {
            if upperText.contains(pattern) { return true }
        }

        for pattern in self.codeExecutionPatterns {
            if upperText.contains(pattern) { return true }
        }

        return false
    }

    private static func removeDangerousCharacters(_ text: String) -> String {
        text.filter { !$0.isNull && !$0.isControl }
    }
}

// MARK: - ValidationError

enum ValidationError: Error {
    case empty(String)
    case exceededLength(String)
    case suspiciousContent(String)

    var localizedDescription: String {
        switch self {
        case let .empty(message):
            message
        case let .exceededLength(message):
            message
        case let .suspiciousContent(message):
            message
        }
    }
}

// MARK: - Character Extensions

extension Character {
    var isNull: Bool { self == "\0" }

    var isControl: Bool {
        let scalars = String(self).unicodeScalars
        return scalars.allSatisfy { scalar in
            let value = scalar.value
            // Control characters: C0 (0x00-0x1F) and C1 (0x7F-0x9F)
            return (value <= 0x1f && value != 0x09 && value != 0x0a && value != 0x0d) ||
                (value >= 0x7f && value <= 0x9f)
        }
    }
}
