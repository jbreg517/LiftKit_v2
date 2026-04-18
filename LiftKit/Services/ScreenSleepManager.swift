import UIKit

final class ScreenSleepManager {
    static let shared = ScreenSleepManager()
    private init() {}

    private var holdCount = 0
    private let lock = NSLock()

    final class Token {
        private let manager: ScreenSleepManager
        private var released = false

        init(manager: ScreenSleepManager) {
            self.manager = manager
        }

        func release() {
            guard !released else { return }
            released = true
            manager.release()
        }

        deinit { release() }
    }

    func hold() -> Token {
        lock.lock()
        holdCount += 1
        updateIdleTimer()
        lock.unlock()
        return Token(manager: self)
    }

    private func release() {
        lock.lock()
        holdCount = max(0, holdCount - 1)
        updateIdleTimer()
        lock.unlock()
    }

    private func updateIdleTimer() {
        let shouldDisable = holdCount > 0
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = shouldDisable
        }
    }
}
