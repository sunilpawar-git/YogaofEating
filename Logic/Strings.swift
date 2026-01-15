import Foundation

/// Centralized string resources for the app.
/// All user-facing strings should be defined here to ensure consistency
/// and enable future localization.
enum Strings {
    // MARK: - Mind Check

    enum MindCheck {
        // Morning
        static let morningTitle = "Morning Intentions"
        static let morningSubtitle = "What are the top 3 things on your mind?"
        static let morningPillText = "What's on your mind?"

        // Evening
        static let eveningTitle = "Evening Review"

        // Common
        static let entryLimitHint = "Up to 3 thoughts"
        static let tapCategoryHint = "Tap a category above to add"
        static let saveButton = "Save"
        static let cancelButton = "Cancel"

        // Entry count
        static func entryCount(_ current: Int, max: Int = 3) -> String {
            "\(current) of \(max)"
        }

        static func thoughtsLogged(_ count: Int) -> String {
            switch count {
            case 1:
                "1 thought logged"
            default:
                "\(count) thoughts logged"
            }
        }

        // Categories
        enum Category {
            static let todo = "To-Do"
            static let gratitude = "Grateful for"
            static let thinking = "Thinking about"
            static let accomplished = "Accomplished"
            static let gratefulFor = "Grateful for"
            static let letGo = "Let go of"
        }

        // Evening Review (accountability flow)
        enum EveningReview {
            static let morningTodosHeader = "Your morning intentions"
            static let gratitudeHeader = "What are you grateful for?"
            static let letGoHeader = "What do you need to let go?"
            static let feelingHeader = "How do you feel?"
            static let noMorningTodos = "No morning todos to review"
            static let accomplished = "Done"
            static let notAccomplished = "Not done"
            static let markAsDone = "Mark as done"
            static let markAsNotDone = "Mark as not done"
        }

        // Historical Mind Check Display
        enum Historical {
            static let mindCheckSectionTitle = "Thoughts & Intentions"
            static let morningHeader = "Morning"
            static let eveningHeader = "Evening"
            static let completed = "Completed"
            static let notCompleted = "Not completed"
            static let noEntries = "No entries"
        }
    }

    // MARK: - Insights

    enum Insight {
        static let dailyTitle = "Daily Insight"
        static let weeklyTitle = "Weekly Summary"
        static let basedOnPatterns = "Based on your patterns"
        static let gotIt = "Got it"
        static let dismiss = "Dismiss"

        // Insight types
        enum InsightType {
            static let foodSleep = "Food & Sleep"
            static let mindsetFeeling = "Mindset & Feeling"
            static let pattern = "Pattern"
            static let encouragement = "Encouragement"
        }
    }

    // MARK: - Timeline

    enum Timeline {
        static let endOfDay = "End of Day"
        static let tapToLog = "TAP TO LOG"
        static let noMealsLogged = "No meals logged"

        static func mealsLogged(_ count: Int) -> String {
            "\(count) meal\(count == 1 ? "" : "s") logged"
        }

        static func itemsCount(_ count: Int) -> String {
            "\(count) item\(count == 1 ? "" : "s")"
        }
    }

    // MARK: - Reflection

    enum Reflection {
        static let sleepQualityTitle = "Sleep Quality"
        static let overallFeelingTitle = "How do you feel?"

        enum Sleep {
            static let great = "Great"
            static let good = "Good"
            static let fair = "Fair"
            static let poor = "Poor"
        }

        enum Feeling {
            static let energized = "Energized"
            static let calm = "Calm"
            static let neutral = "Neutral"
            static let tired = "Tired"
            static let heavy = "Heavy"
        }
    }

    // MARK: - Common

    enum Common {
        static let done = "Done"
        static let cancel = "Cancel"
        static let save = "Save"
        static let edit = "Edit"
        static let delete = "Delete"
        static let today = "Today"
        static let yesterday = "Yesterday"
    }

    // MARK: - Accessibility

    enum Accessibility {
        static let addMealButton = "Add Meal"
        static let settingsButton = "Settings"
        static let mindCheckComplete = "Mind check complete"

        static func mindCheckEntries(_ count: Int) -> String {
            "\(count) entries"
        }
    }
}
