// MARK: - Strings.SmileyMood

extension Strings {
    enum SmileyMood {
        static let serene = "Serene"
        static let neutral = "Neutral"
        static let thoughtful = "Thoughtful"
        static let concerned = "Concerned"
        static let overwhelmed = "Overwhelmed"

        static let sereneTagline = "You're nourishing yourself beautifully today."
        static let neutralTagline = "You're holding steady — there's room to grow."
        static let thoughtfulTagline = "Something's pulling on your energy right now."
        static let concernedTagline = "Yesterday asked a lot. Today is a fresh start."
        static let overwhelmedTagline = "Your body is asking for gentler choices today."
    }
}

// MARK: - Strings.WellbeingBreakdown additions

extension Strings.WellbeingBreakdown {
    /// Shown in the progress pill when the user is already at the top state.
    static let atTop = "You're at the top — keep it going."

    /// Format string for the progress pill. Args: pts (Int), next emoji (String), next name (String).
    /// Example output: "8 pts from 🙂 Serene"
    static let progressFmt = "%d pts from %@ %@"

    /// Warm label above weak-dimension chips. Replaces the old "Needs attention:" copy.
    static let worthNurturing = "Worth some love today:"

    // MARK: - Accessibility Labels

    /// Accessibility label for the state hero emoji. Arg: mood display name (String).
    static let heroEmojiAccessibilityFmt = "%@ state"

    /// Accessibility label for each weak dim chip. Arg: dimension display name (String).
    static let weakDimChipAccessibilityFmt = "%@, worth some attention"

    /// Accessibility label for each dimension bar. Args: name (String), percent (Int).
    static let dimensionBarAccessibilityFmt = "%@: %d percent"
}
