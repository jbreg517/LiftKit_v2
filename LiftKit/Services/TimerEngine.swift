import Foundation
import UserNotifications

// MARK: - Timer Config

struct TimerConfig: Codable, Equatable {
    var type: TimerType
    var durationMinutes: Int
    var durationSeconds: Int
    var rounds: Int
    var workSeconds: Int
    var restSeconds: Int
    var restBetweenSets: Int

    static func defaultConfig(for type: TimerType) -> TimerConfig {
        switch type {
        case .amrap:
            return TimerConfig(type: .amrap, durationMinutes: 10, durationSeconds: 0,
                               rounds: 1, workSeconds: 0, restSeconds: 0, restBetweenSets: 90)
        case .emom:
            return TimerConfig(type: .emom, durationMinutes: 10, durationSeconds: 0,
                               rounds: 10, workSeconds: 60, restSeconds: 0, restBetweenSets: 0)
        case .forTime:
            return TimerConfig(type: .forTime, durationMinutes: 20, durationSeconds: 0,
                               rounds: 1, workSeconds: 0, restSeconds: 0, restBetweenSets: 0)
        case .intervals:
            return TimerConfig(type: .intervals, durationMinutes: 0, durationSeconds: 0,
                               rounds: 8, workSeconds: 40, restSeconds: 20, restBetweenSets: 0)
        case .reps:
            return TimerConfig(type: .reps, durationMinutes: 0, durationSeconds: 0,
                               rounds: 1, workSeconds: 0, restSeconds: 0, restBetweenSets: 90)
        case .manual:
            return TimerConfig(type: .manual, durationMinutes: 0, durationSeconds: 0,
                               rounds: 1, workSeconds: 0, restSeconds: 0, restBetweenSets: 0)
        }
    }

    var totalDurationSeconds: Int {
        durationMinutes * 60 + durationSeconds
    }

    var totalWorkoutSeconds: Int {
        switch type {
        case .amrap, .forTime:
            return totalDurationSeconds
        case .emom:
            return rounds * 60
        case .intervals:
            return (workSeconds + restSeconds) * rounds
        case .reps, .manual:
            return 0
        }
    }
}

// MARK: - Timer Phase

enum TimerPhase: Equatable {
    case idle
    case countdown(Int)
    case work
    case rest
    case complete
}

// MARK: - Timer Engine

@Observable
final class TimerEngine {
    private(set) var phase: TimerPhase = .idle
    private(set) var isRunning = false
    private(set) var timeRemaining: TimeInterval = 0
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var currentRound = 1
    private(set) var totalRounds = 1

    var config: TimerConfig?
    var onPhaseChange: ((TimerPhase) -> Void)?
    var onComplete: (() -> Void)?
    var onTick: (() -> Void)?

    private var displayLink: CADisplayLink?
    private var phaseEndDate: Date?
    private var phaseStartDate: Date?
    private var pausedTimeRemaining: TimeInterval?
    private var pausedElapsed: TimeInterval?
    private let notificationPrefix: String
    private var screenSleepToken: ScreenSleepManager.Token?

    init(notificationPrefix: String = UUID().uuidString) {
        self.notificationPrefix = notificationPrefix
    }

    deinit {
        stop()
    }

    // MARK: - Public API

    func start(config: TimerConfig) {
        self.config = config
        self.totalRounds = config.rounds
        self.currentRound = 1
        scheduleInitialCountdown()
    }

    func startRestTimer(_ seconds: TimeInterval) {
        cancelNotifications()
        currentRound = 1
        totalRounds = 1
        enterPhase(.rest, duration: seconds)
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        displayLink?.invalidate()
        displayLink = nil
        pausedTimeRemaining = timeRemaining
        pausedElapsed = elapsedTime
        cancelNotifications()
        screenSleepToken?.release()
        screenSleepToken = nil
    }

    func resume() {
        guard !isRunning, let paused = pausedTimeRemaining else { return }
        isRunning = true
        if let cfg = config, (cfg.type == .forTime || cfg.type == .manual) {
            phaseStartDate = Date().addingTimeInterval(-(pausedElapsed ?? 0))
            phaseEndDate = nil
        } else {
            phaseEndDate = Date().addingTimeInterval(paused)
        }
        pausedTimeRemaining = nil
        pausedElapsed = nil
        startDisplayLink()
        screenSleepToken = ScreenSleepManager.shared.hold()
        scheduleNotificationsFromCurrentState()
    }

    func skip() {
        guard let cfg = config else { return }
        switch cfg.type {
        case .emom:
            advanceEMOMRound()
        case .intervals:
            advanceIntervalPhase()
        case .reps:
            completeRestTimer()
        default:
            completeCurrentPhase()
        }
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        isRunning = false
        phaseEndDate = nil
        phaseStartDate = nil
        pausedTimeRemaining = nil
        pausedElapsed = nil
        timeRemaining = 0
        elapsedTime = 0
        currentRound = 1
        phase = .idle
        cancelNotifications()
        screenSleepToken?.release()
        screenSleepToken = nil
    }

    var formattedTime: String {
        let t = phase == .work && config?.type == .forTime
            ? elapsedTime
            : (phase == .work && config?.type == .manual ? elapsedTime : timeRemaining)
        return formatTime(t)
    }

    func formatTime(_ t: TimeInterval) -> String {
        let total = max(0, Int(t))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Phase management

    private func scheduleInitialCountdown() {
        enterPhase(.countdown(10), duration: 10)
    }

    private func enterPhase(_ newPhase: TimerPhase, duration: TimeInterval) {
        cancelNotifications()
        phase = newPhase
        isRunning = true
        timeRemaining = duration

        if case .work = newPhase, let cfg = config,
           (cfg.type == .forTime || cfg.type == .manual) {
            phaseStartDate = Date()
            phaseEndDate = nil
        } else {
            phaseEndDate = Date().addingTimeInterval(duration)
        }

        screenSleepToken?.release()
        screenSleepToken = ScreenSleepManager.shared.hold()
        startDisplayLink()
        onPhaseChange?(newPhase)
        scheduleNotificationsFromCurrentState()
    }

    private func startDisplayLink() {
        displayLink?.invalidate()
        let dl = CADisplayLink(target: self, selector: #selector(tick))
        dl.add(to: .main, forMode: .common)
        displayLink = dl
    }

    @objc private func tick() {
        guard isRunning else { return }

        let now = Date()

        if let end = phaseEndDate {
            let remaining = end.timeIntervalSince(now)
            if remaining <= 0 {
                timeRemaining = 0
                completeCurrentPhase()
                return
            }
            timeRemaining = remaining
        } else if let start = phaseStartDate {
            elapsedTime = now.timeIntervalSince(start)
            timeRemaining = elapsedTime
        }

        onTick?()
    }

    private func completeCurrentPhase() {
        guard let cfg = config else { stop(); return }

        switch cfg.type {
        case .amrap:
            finishWorkout()

        case .emom:
            if case .countdown = phase {
                enterPhase(.work, duration: TimeInterval(cfg.workSeconds > 0 ? cfg.workSeconds : 60))
            } else {
                advanceEMOMRound()
            }

        case .forTime:
            if case .countdown = phase {
                phase = .work
                phaseStartDate = Date()
                phaseEndDate = nil
                onPhaseChange?(.work)
            }

        case .intervals:
            if case .countdown = phase {
                enterPhase(.work, duration: TimeInterval(cfg.workSeconds))
            } else {
                advanceIntervalPhase()
            }

        case .reps:
            completeRestTimer()

        case .manual:
            if case .countdown = phase {
                phase = .work
                phaseStartDate = Date()
                phaseEndDate = nil
                onPhaseChange?(.work)
            }
        }
    }

    private func advanceEMOMRound() {
        guard let cfg = config else { return }
        if currentRound >= cfg.rounds {
            finishWorkout()
        } else {
            currentRound += 1
            enterPhase(.work, duration: TimeInterval(cfg.workSeconds > 0 ? cfg.workSeconds : 60))
        }
    }

    private func advanceIntervalPhase() {
        guard let cfg = config else { return }
        if case .work = phase {
            enterPhase(.rest, duration: TimeInterval(cfg.restSeconds))
        } else if case .rest = phase {
            if currentRound >= cfg.rounds {
                finishWorkout()
            } else {
                currentRound += 1
                enterPhase(.work, duration: TimeInterval(cfg.workSeconds))
            }
        }
    }

    private func completeRestTimer() {
        finishWorkout()
    }

    private func finishWorkout() {
        displayLink?.invalidate()
        displayLink = nil
        isRunning = false
        phase = .complete
        cancelNotifications()
        screenSleepToken?.release()
        screenSleepToken = nil
        onPhaseChange?(.complete)
        onComplete?()
    }

    // MARK: - Notifications

    private func scheduleNotificationsFromCurrentState() {
        guard let cfg = config else { return }
        cancelNotifications()

        let center = UNUserNotificationCenter.current()
        var notifications: [(identifier: String, delay: TimeInterval, title: String, body: String)] = []

        switch cfg.type {
        case .amrap:
            if let end = phaseEndDate {
                let delay = end.timeIntervalSinceNow
                if delay > 0 {
                    notifications.append((
                        identifier: "\(notificationPrefix)-complete",
                        delay: delay,
                        title: "AMRAP Complete!",
                        body: "Time's up. Log your rounds."
                    ))
                }
            }

        case .emom:
            var delay = phaseEndDate?.timeIntervalSinceNow ?? 0
            for round in currentRound...cfg.rounds {
                if delay > 0 {
                    notifications.append((
                        identifier: "\(notificationPrefix)-round-\(round)",
                        delay: delay,
                        title: "EMOM Round \(round) complete",
                        body: round < cfg.rounds ? "Next round starting!" : "Workout complete!"
                    ))
                }
                delay += TimeInterval(cfg.workSeconds > 0 ? cfg.workSeconds : 60)
                if notifications.count >= 32 { break }
            }

        case .intervals:
            var delay = phaseEndDate?.timeIntervalSinceNow ?? 0
            var inWork = (phase == .work)
            var round = currentRound
            var count = 0
            while round <= cfg.rounds && count < 32 {
                if delay > 0 {
                    notifications.append((
                        identifier: "\(notificationPrefix)-interval-\(count)",
                        delay: delay,
                        title: inWork ? "REST" : "WORK",
                        body: inWork ? "Rest now" : "Go!"
                    ))
                }
                if inWork {
                    delay += TimeInterval(cfg.restSeconds)
                    inWork = false
                } else {
                    round += 1
                    delay += TimeInterval(cfg.workSeconds)
                    inWork = true
                }
                count += 1
            }

        default:
            break
        }

        for note in notifications {
            let content = UNMutableNotificationContent()
            content.title = note.title
            content.body = note.body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, note.delay), repeats: false)
            let request = UNNotificationRequest(identifier: note.identifier, content: content, trigger: trigger)
            center.add(request, withCompletionHandler: nil)
        }
    }

    private func cancelNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { [weak self] requests in
            guard let prefix = self?.notificationPrefix else { return }
            let ids = requests.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}

// MARK: - CADisplayLink bridge (requires UIKit)
import QuartzCore
