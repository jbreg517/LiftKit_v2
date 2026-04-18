import Foundation

enum TimerType: String, Codable, CaseIterable {
    case amrap     = "AMRAP"
    case emom      = "EMOM"
    case forTime   = "For Time"
    case intervals = "Intervals"
    case reps      = "Reps"
    case manual    = "Manual"

    var icon: String {
        switch self {
        case .amrap:     return "timer"
        case .emom:      return "clock.arrow.circlepath"
        case .forTime:   return "stopwatch.fill"
        case .intervals: return "bolt.fill"
        case .reps:      return "dumbbell.fill"
        case .manual:    return "hand.tap.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .amrap:     return "As many rounds as possible"
        case .emom:      return "Every minute on the minute"
        case .forTime:   return "Complete before the time cap"
        case .intervals: return "Work and rest phases"
        case .reps:      return "Log sets with rest timer"
        case .manual:    return "Elapsed timer, you control"
        }
    }

    var isCountdown: Bool {
        switch self {
        case .amrap, .emom, .intervals: return true
        case .forTime, .manual, .reps:  return false
        }
    }
}
