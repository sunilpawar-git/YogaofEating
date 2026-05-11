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

        /// Label for the "Back to Today" navigation button shown on historical days.
        static let backToToday = "Back to Today"

        /// Formats the sleep quality display name for use in the context subtext.
        /// Centralizes lowercasing so `DateContextProvider` does not mix display-string
        /// transformation with formatting logic.
        static func sleptQualityFormatted(quality: SleepQuality) -> String {
            self.sleptQuality(quality.displayName.lowercased())
        }
    }

    // MARK: - Journal Block

    enum Journal {
        /// Placeholder text for the meal text field.
        static let placeholder = "What are you eating?"

        /// Delete confirmation alert title.
        static let deleteAlertTitle = "Delete this meal?"

        /// Delete confirmation alert body message.
        static let deleteAlertMessage = "This action cannot be undone."

        /// Accessibility label for the done (confirm) button on a meal entry.
        static let doneButtonLabel = "Done"

        /// Accessibility hint for the done button.
        static let doneButtonHint = "Confirm meal entry and analyze"

        /// Formats item count for display in meal card footer (singular/plural).
        static func itemCount(_ count: Int) -> String {
            "\(count) item\(count == 1 ? "" : "s")"
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

    // MARK: - Components

    enum Components {
        /// Placeholder text shown in BreathingContentView while processing.
        static let breathe = "Breathe..."
    }

    // MARK: - Validation Errors (Phase 4)

    enum Validation {
        static let errorTitle = "Invalid Input"
        static let dismissButton = "OK"

        // Field-specific error messages
        enum MealDescription {
            static let empty = "Please enter what you ate"
            static let tooLong = "Meal description is too long (max 500 characters)"
            static let suspicious = "Your entry contains characters we can't accept. Please remove any HTML or special markup."
        }

        enum JournalEntry {
            static let empty = "Please write something"
            static let tooLong = "Journal entry is too long (max 2,000 characters)"
            static let suspicious = "Your entry contains characters we can't accept. Please remove any HTML or special markup."
        }

        enum SleepNotes {
            static let tooLong = "Sleep notes are too long (max 300 characters)"
            static let suspicious = "Your entry contains characters we can't accept. Please remove any HTML or special markup."
        }

        enum MorningThoughts {
            static let tooLong = "Morning thoughts are too long (max 500 characters)"
            static let suspicious = "Your entry contains characters we can't accept. Please remove any HTML or special markup."
        }

        enum TodoItem {
            static let empty = "Please enter your to-do"
            static let tooLong = "To-do item is too long (max 150 characters)"
            static let suspicious = "Your entry contains characters we can't accept. Please remove any HTML or special markup."
        }
    }

    // MARK: - Accessibility

    enum Settings {
        /// Generic sync failure message shown to users when the underlying error is not user-actionable.
        /// Never expose provider-specific error strings (Firebase, NSError domains) to users.
        static let syncFailedGeneric = "Sync failed. Please check your connection and try again."
    }

    enum Accessibility {
        static let addMealButton = "Add Meal"
        static let addMealHint = "Tap to log a new meal"
        static let addMealWithInsight = "Add Meal or Hold for Insight"
        static let addMealWithInsightHint = "Tap to log meal, hold to view insight"
        static let settingsButton = "Settings"
        static let mindCheckComplete = "Mind check complete"

        /// Label for the small "+" button that opens the recent meals sheet.
        static let addMealFromRecent = "Add from recent meals"

        /// Hint explaining what the recent meals button does.
        static let addMealFromRecentHint = "Shows meals from the past 3 days"

        static func mindCheckEntries(_ count: Int) -> String {
            "\(count) entries"
        }
    }

    // MARK: - Enriched Insight

    enum EnrichedInsight {
        static let sheetTitle = "Today's Intelligence"
        static let causalHeading = "Why your smiley changed"
        static let noDataHeadline = "Keep logging to unlock insights"
        static let headlineStrong = "Strong day — all systems are working for you"
        static let headlineSteady = "A steady day with room to grow"
        static let headlineThoughtful = "A thoughtful day — something to reflect on"
        static let headlineChallenging = "A challenging day — be gentle with yourself"
    }

    // MARK: - Correlation Category Display Names

    enum Correlation {
        static let foodToSleep = "Food & Sleep"
        static let foodToMood = "Food & Mood"
        static let focusToFeeling = "Focus & Feeling"
        static let timingPattern = "Timing Pattern"
        static let foodDebt = "Food & Momentum"
        static let sleepRecoveryCarryover = "Sleep Recovery"
        static let intentionFollowthrough = "Intention Gap"
        static let journalTonePrediction = "Mood Forecast"
        static let sleepMismatch = "Sleep Mismatch"
        static let carryOverLoad = "Carry-Over Load"
    }

    // MARK: - Wellbeing Breakdown Sheet

    enum WellbeingBreakdown {
        static let sheetTitle = "Today's Wellbeing"
        static let whyHeading = "Why did my smiley change?"
        static let done = "Done"
        static let overallLabel = "Overall"
        static let weakDimensionPrefix = "Needs attention:"
        static let detectedSignalsLabel = "Detected tone:"
    }

    // MARK: - Synthesis (WellbeingDimensions + TextSignal)

    enum Synthesis {
        enum Dimension {
            static let physicalLoad = "Physical"
            static let emotionalTone = "Emotional"
            static let cognitiveClarity = "Clarity"
            static let behavioralMomentum = "Momentum"
        }

        enum Signal {
            static let stressed = "Stress detected"
            static let clear = "Clear mindset"
            static let overwhelmed = "Feeling overwhelmed"
            static let grateful = "Gratitude day"
            static let agentive = "Strong agency"
            static let selfCompassionate = "Self-compassion"
            static let neutral = "Neutral tone"
        }

        enum CausalNarrative {
            static let physical = "Your food choices are driving today's state."
            static let emotional = "Your mood and feelings are shaping today."
            static let cognitive = "Sleep quality is influencing your clarity."
            static let behavioral = "Your follow-through on intentions is leading today."
            static let balanced = "All dimensions are contributing equally today."
        }
    }

    // MARK: - HealthKit Activity

    enum HealthKit {
        static let activityTrackingTitle = "Activity Tracking"
        static let activityTrackingDescription = "Grants access to today's active and resting calories for a live calorie goal."
        static let activityPermissionDenied = "Enable Activity access in Settings → Health → Data Access."
    }
}
