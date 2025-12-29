import AudioToolbox
import AVFoundation
#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

/// Handles high-fidelity sensory feedback for a "Yoga" feel.
class SensoryService {
    static let shared = SensoryService()

    private var audioPlayer: AVAudioPlayer?

    private init() {
        #if canImport(UIKit)
            // Pre-configure audio session (iOS only)
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    /// Provides a mindful haptic "nudge".
    func playNudge(style: FeedbackStyle = .medium) {
        #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: style.uiStyle)
            generator.prepare()
            generator.impactOccurred()
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
        let soundName = scale > 1.0 ? "thump" : "tink"
        self.playSound(named: soundName)
    }
}
