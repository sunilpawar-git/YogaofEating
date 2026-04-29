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
        static let tapToLogWithInsight = "TAP TO LOG · HOLD FOR INSIGHT"
        static let noMealsLogged = "No meals logged"

        /// Shown above the smiley when no meals have been logged today.
        /// Replaces the static quote in empty state to give contextual warmth.
        static let emptyStateGreeting = "Start your day's journal"

        /// Accessibility label for the daily quote text.
        static let quoteAccessibility = "Daily mindful eating quote"

        static func mealsLogged(_ count: Int) -> String {
            "\(count) meal\(count == 1 ? "" : "s") logged"
        }

        static func itemsCount(_ count: Int) -> String {
            "\(count) item\(count == 1 ? "" : "s")"
        }

        /// Shown above the smiley when 2+ meals are logged.
        /// Gives a quick ambient overview of the day without requiring interaction.
        static func daySummary(avgScore: Int, mealCount: Int) -> String {
            "Avg. \(avgScore)% · \(mealCount) meal\(mealCount == 1 ? "" : "s")"
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

    // MARK: - Date Header (Phase 4)

    enum DateHeader {
        /// Shown before 10am when no sleep has been logged yet.
        static let goodMorning = "Good morning"

        /// Shown when sleep quality has been logged. Pass quality display name lowercased.
        static func sleptQuality(_ quality: String) -> String {
            "Slept \(quality)"
        }

        /// Shown when 1+ meals have been logged and no sleep-based context is active.
        static func mealsSoFar(_ count: Int) -> String {
            "\(count) meal\(count == 1 ? "" : "s") so far"
        }

        /// Shown when viewing a historical day. Pass the number of days ago.
        static func daysAgo(_ count: Int) -> String {
            "\(count) day\(count == 1 ? "" : "s") ago"
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
        static let addMealHint = "Tap to log a new meal"
        static let addMealWithInsight = "Add Meal or Hold for Insight"
        static let addMealWithInsightHint = "Tap to log meal, hold to view insight"
        static let settingsButton = "Settings"
        static let mindCheckComplete = "Mind check complete"

        static func mindCheckEntries(_ count: Int) -> String {
            "\(count) entries"
        }
    }
}
