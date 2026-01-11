import AudioToolbox
import AVFoundation
#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

/// Protocol for sensory feedback services, enabling dependency injection and testing
protocol SensoryServiceProtocol {
    /// Provides a mindful haptic "nudge".
    func playNudge(style: SensoryService.FeedbackStyle)

    /// Plays a system sound based on AI suggestions or mood
    func playSound(named soundName: String)

    /// Legacy method for scale-based sounds
    func playSound(for scale: Double)

    /// Plays personalized haptic feedback based on meal health score and user risk level
    func playMealFeedbackHaptic(for healthScore: Double, riskLevel: HealthRiskLevel, userDefaults: UserDefaults?)

    /// Determines appropriate feedback style based on health score and risk level
    func getFeedbackStyle(for healthScore: Double, riskLevel: HealthRiskLevel) -> SensoryService.FeedbackStyle
}

/// Handles high-fidelity sensory feedback for a "Yoga" feel.
class SensoryService: SensoryServiceProtocol {
    static let shared = SensoryService()

    private var audioPlayer: AVAudioPlayer?

    #if canImport(UIKit)
        // Reuse haptic generators for smoother feedback
        private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
        private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
        private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    #endif

    private init() {
        #if canImport(UIKit)
            // Pre-configure audio session (iOS only)
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)

            // Prepare generators for instant response
            self.lightGenerator.prepare()
            self.mediumGenerator.prepare()
            self.heavyGenerator.prepare()
        #endif
    }

    /// Provides a mindful haptic "nudge".
    func playNudge(style: FeedbackStyle = .medium) {
        #if canImport(UIKit)
            let generator: UIImpactFeedbackGenerator = switch style {
            case .light:
                lightGenerator
            case .medium, .soft:
                mediumGenerator
            case .heavy:
                heavyGenerator
            }
            generator.impactOccurred()
            // Prepare for next use
            generator.prepare()
        #elseif canImport(AppKit)
            // macOS haptic feedback
            let performer = NSHapticFeedbackManager.defaultPerformer
            let hapticStyle: NSHapticFeedbackManager.FeedbackPattern = switch style {
            case .light:
                .generic
            case .medium:
                .alignment
            case .heavy, .soft:
                .levelChange
            }
            performer.perform(hapticStyle, performanceTime: .default)
        #endif
    }

    /// Cross-platform feedback style enum
    enum FeedbackStyle {
        case light
        case medium
        case heavy
        case soft

        #if canImport(UIKit)
            var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle {
                switch self {
                case .light:
                    .light
                case .medium:
                    .medium
                case .heavy:
                    .heavy
                case .soft:
                    .medium
                }
            }
        #endif
    }

    /// Plays a system sound based on AI suggestions
    func playSound(named soundName: String) {
        // Check if sounds are enabled in user settings
        let isSoundEnabled = UserDefaults.standard.object(forKey: "sound_enabled") as? Bool ?? true
        guard isSoundEnabled else { return }

        let systemSoundID: SystemSoundID = switch soundName.lowercased() {
        case "chime":
            1016
        case "thump":
            1057
        case "tink":
            1103
        case "heavy_thump":
            1050
        default:
            1103
        }
        AudioServicesPlaySystemSound(systemSoundID)
    }

    /// Legacy method for scale-based sounds
    func playSound(for scale: Double) {
        // Check if sounds are enabled in user settings
        let isSoundEnabled = UserDefaults.standard.object(forKey: "sound_enabled") as? Bool ?? true
        guard isSoundEnabled else { return }

        let soundName = scale > 1.0 ? "thump" : "tink"
        self.playSound(named: soundName)
    }

    // MARK: - Personalized Haptic Feedback

    /// Plays personalized haptic feedback based on meal health score and user's health risk level
    /// - Parameters:
    ///   - healthScore: Health score of the meal (0.0 - 1.0)
    ///   - riskLevel: User's health risk level (low/medium/high)
    ///   - userDefaults: Optional UserDefaults instance (for testing). Uses .standard if nil
    func playMealFeedbackHaptic(
        for healthScore: Double,
        riskLevel: HealthRiskLevel,
        userDefaults: UserDefaults? = nil
    ) {
        let defaults = userDefaults ?? UserDefaults.standard

        // Check if haptics are enabled in user settings
        let areHapticsEnabled = defaults.object(forKey: "haptics_enabled") as? Bool ?? true
        guard areHapticsEnabled else { return }

        // Determine appropriate feedback style
        let style = self.getFeedbackStyle(for: healthScore, riskLevel: riskLevel)

        // Play the haptic
        self.playNudge(style: style)
    }

    /// Determines the appropriate haptic feedback style based on health score and risk level
    /// - Parameters:
    ///   - healthScore: Health score of the meal (0.0 - 1.0)
    ///   - riskLevel: User's health risk level
    /// - Returns: Feedback style (soft/light/medium/heavy)
    func getFeedbackStyle(for healthScore: Double, riskLevel: HealthRiskLevel) -> FeedbackStyle {
        // Healthy meals (score > 0.65): Celebrate with soft haptic
        if healthScore > 0.65 {
            return .soft
        }

        // Neutral meals (0.35 - 0.65): Light feedback
        if healthScore >= 0.35 {
            return .light
        }

        // Unhealthy meals (score < 0.35): Escalate intensity based on risk level
        switch riskLevel {
        case .low:
            return .light // Gentle nudge for low-risk users
        case .medium:
            return .medium // Firmer nudge for medium-risk users
        case .high:
            return .heavy // Strong warning for high-risk users
        }
    }
}
