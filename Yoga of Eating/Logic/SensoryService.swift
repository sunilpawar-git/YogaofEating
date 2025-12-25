import UIKit
import AVFoundation

/// Handles high-fidelity sensory feedback for a "Yoga" feel.
class SensoryService {
    static let shared = SensoryService()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        // Pre-configure audio session
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    /// Provides a mindful haptic "nudge".
    func playNudge(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Plays a low-frequency mindful sound.
    func playSound(for scale: Double) {
        // In a real app, we'd load a small .wav file.
        // For this demo, we use a system sound or a simplified trigger.
        let systemSoundID: SystemSoundID = scale > 1.0 ? 1057 : 1103 // Thump vs Tink
        AudioServicesPlaySystemSound(systemSoundID)
    }
}
