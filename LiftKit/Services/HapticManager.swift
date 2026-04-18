import UIKit

final class HapticManager {
    static let shared = HapticManager()
    private init() {}

    private let lightImpact  = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()

    func buttonTap() {
        guard UserDefaults.standard.bool(forKey: "hapticsEnabled") != false else { return }
        lightImpact.impactOccurred()
    }

    func setLogged() {
        guard UserDefaults.standard.bool(forKey: "hapticsEnabled") != false else { return }
        mediumImpact.impactOccurred()
    }

    func personalRecord() {
        guard UserDefaults.standard.bool(forKey: "hapticsEnabled") != false else { return }
        notification.notificationOccurred(.success)
    }

    func timerComplete() {
        guard UserDefaults.standard.bool(forKey: "hapticsEnabled") != false else { return }
        notification.notificationOccurred(.success)
    }
}
