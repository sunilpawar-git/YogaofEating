import Foundation

/// Single Source of Truth (SSOT) for all input validation limits across the app.
/// This enum centralizes field-specific length constraints to ensure consistency.
/// All Views and ViewModels reference this enum instead of hardcoding limits.
enum ValidationLimits {
    // MARK: - Field Length Limits (Characters)

    /// Maximum characters for meal descriptions.
    /// Used by: JournalBlockView, InputValidator, MainViewModel
    static let mealDescription = 500

    /// Maximum characters for journal entries (evening reflection).
    /// Used by: ReflectSections, InputValidator, MainViewModel
    static let journalEntry = 1000

    /// Maximum characters for sleep notes (optional field).
    /// Used by: HighlightSections, InputValidator, MainViewModel
    static let sleepNotes = 1000

    /// Maximum characters for morning thoughts (optional field).
    /// Used by: HighlightSections, InputValidator, MainViewModel
    static let morningThoughts = 1000

    /// Maximum characters for to-do items.
    /// Used by: HighlightSections, InputValidator, MainViewModel
    static let todoItem = 150

    // MARK: - Universal Limit (Fallback)

    /// Universal character limit used as the app-wide UI truncation ceiling.
    /// All free-text fields are clamped to this value at the ViewModel boundary
    /// (AppTheme.TextEntry.maxCharacters) before field-specific validation runs.
    /// Individual field limits (sleepNotes, morningThoughts, etc.) may be lower
    /// and are enforced by InputValidator after clamping.
    static let universal = 1000
}
