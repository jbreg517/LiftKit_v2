import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var name: String
    var startedAt: Date
    var completedAt: Date?
    var notes: String?
    var workoutType: String?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutEntry.session)
    var entries: [WorkoutEntry]

    init(name: String,
         notes: String? = nil,
         workoutType: String? = nil) {
        self.id          = UUID()
        self.name        = name
        self.startedAt   = Date()
        self.completedAt = nil
        self.notes       = notes
        self.workoutType = workoutType
        self.entries     = []
    }

    var duration: TimeInterval {
        guard let completed = completedAt else { return 0 }
        return completed.timeIntervalSince(startedAt)
    }

    var isActive: Bool { completedAt == nil }

    var totalVolume: Double {
        entries.flatMap(\.sets).compactMap { set in
            guard let w = set.weight, let r = set.reps else { return nil }
            return w * Double(r)
        }.reduce(0, +)
    }

    var timerType: TimerType? {
        guard let raw = workoutType else { return nil }
        return TimerType(rawValue: raw)
    }

    var formattedDuration: String {
        let total = Int(duration)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return s > 0 ? "\(m)m \(s)s" : "\(m)m" }
        return "\(s)s"
    }
}
