import AVFoundation
import AudioToolbox

final class SoundManager {
    static let shared = SoundManager()
    private init() {}

    func configure() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func playTick() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1057)
    }

    func playComplete() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1025)
    }

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "soundEnabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "soundEnabled")
    }
}
