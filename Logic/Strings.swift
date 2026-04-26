// swiftlint:disable file_length
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
            static let observationHeader = "What did you notice today?"
            static let observationPlaceholder = "e.g. I felt more alert after a lighter lunch..."
            static let feelingHeader = "How do you feel?"
            static let noMorningTodos = "No morning todos to review"
            static let accomplished = "Done"
            static let notAccomplished = "Not done"
            static let markAsDone = "Mark as done"
            static let markAsNotDone = "Mark as not done"
            static let toggleHint = "Tap to toggle completion status"

            static func accessibilityLabel(_ text: String, accomplished: Bool) -> String {
                "\(text), \(accomplished ? "completed" : "not completed")"
            }
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
        static let weeklyWinsTitle = "Wins"
        static let weeklyImprovementsTitle = "Improvement Areas"
        static let weeklyWinPrefix = "Win"
        static let basedOnPatterns = "Based on your patterns"
        static let gotIt = "Got it"
        static let dismiss = "Dismiss"

        static let basedOn = "Based on:"

        enum InsightType {
            static let foodSleep = "Food & Sleep"
            static let mindsetFeeling = "Mindset & Feeling"
            static let pattern = "Pattern"
            static let encouragement = "Encouragement"
            static let intentAlignment = "Intent Alignment"
            static let focusFood = "Focus & Food"
        }
    }

    // MARK: - Timeline

    enum Timeline {
        static let endOfDay = "End of Day"
        static let tapToLog = "TAP TO LOG"
        static let tapToLogHoldForInsight = "TAP TO LOG · HOLD FOR INSIGHT"
        static let noMealsLogged = "No meals logged"
        static let avgHealthScore = "Avg. Health Score"
        static let noItemsLogged = "No items logged"
        static let copyMeal = "Copy meal to today"

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

    // MARK: - Reflect

    enum Reflect {
        static let title = "Set Your Intention"
        static let subtitle = "How's your energy, and what's your eating goal today?"
        static let energyLabel = "Morning Energy"
        static let intentionPlaceholder = "e.g. Eat lighter meals, No sugar today..."
        static let intentionLabel = "Today's Intention"
        static let saveButton = "Set Intention"
        static let skipButton = "Skip"
        static let defaultIntention = "Eat mindfully"
        static let energyLabels = ["Low", "Tired", "Okay", "Good", "Great"]
        static let energyEmojis = ["😴", "🥱", "😐", "🙂", "⚡️"]
    }

    enum DayRing {
        static let reflect = "Reflect"
        static let laser = "Laser"
        static let highlight = "Highlight"
        static let energise = "Energize"
    }

    enum BIS {
        static let title = "Body Intelligence"
        static let subtitle = "Daily composite score"
        static let moduleLabel = "Modules"
        static let sleepLabel = "Sleep"
        static let nutritionLabel = "Nutrition"
        static let executionLabel = "Execution"

        static func avgLabel(_ value: Int) -> String { "BIS Avg: \(value)" }
    }

    enum Trends {
        static let title = "Trends"
        static let bisTitle = "Body Intelligence"
        static let moduleTitle = "Module Completion"
        static let sleepTitle = "Sleep Score"
        static let archetypePrefix = "Archetype"
        static let axisDate = "Date"
        static let axisBIS = "BIS"
        static let axisSleep = "Sleep"
        static let axisReflect = "Reflect"
        static let axisLaser = "Laser"
        static let axisHighlight = "Highlight"
        static let axisEnergise = "Energise"
        static let emptyState = "Log more days to see trends here."
    }

    enum Premium {
        static let navTitle = "Premium"
        static let heading = "Upgrade to Premium"
        static let subtitle = "Unlock trends, archetype coaching, and PDF export."
        static let trendFeature = "Trend charts"
        static let archetypeFeature = "Energy archetypes"
        static let pdfFeature = "PDF export"
        static let productsUnavailable = "Products unavailable right now."
        static let restorePurchases = "Restore Purchases"
        static let close = "Close"
        static let exportPdf = "Export PDF"
        static let exportFailed = "Export unavailable"
        static let purchaseFailed = "Purchase Failed"
        static let purchaseFailedMessage = "Something went wrong. Please try again."
    }

    enum EnergyArchetype {
        static let steadyState = "Steady State"
        static let spikeDip = "Spike & Dip"
        static let nocturnalOwl = "Nocturnal Owl"
        static let earlyBird = "Early Bird"
        static let inconsistent = "Inconsistent"
    }

    enum Focus {
        static let promptTitle = "How's your focus?"
        static let scattered = "Scattered"
        static let okay = "Okay"
        static let lockedIn = "Locked In"
        static let scatteredIcon = "cloud"
        static let okayIcon = "circle"
        static let lockedInIcon = "bolt.fill"
    }

    // MARK: - MicroReflection

    enum MicroReflection {
        static let hungerLabel = "Hunger before"
        static let satisfactionLabel = "Satisfaction after"
        static let overeatingHint =
            "You often eat past hunger — try smaller portions"
        static let notHungryAtDinner =
            "You tend to eat dinner without being hungry"
    }

    // MARK: - Streak

    enum Streak {
        static let minimumDisplay = 2
        static let flameEmoji = "🔥"

        static func pill(_ count: Int) -> String {
            "\(count) day streak"
        }

        static let bestRecord = "Best"
        static let streakPopoverTitle = "Your Streak"
    }

    // MARK: - Nudge

    enum Nudge {
        static let streakRisk =
            "Don't break your streak — log your meal"
        static let gentle = "How are you eating today?"

        static func streakKeepGoing(_ count: Int) -> String {
            "\(count)-day streak! Keep it going — log your meal"
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
