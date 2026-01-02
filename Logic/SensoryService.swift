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
}
