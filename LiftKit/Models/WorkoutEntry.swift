import Foundation
import SwiftData

@Model
final class WorkoutEntry {
    var id: UUID
    var exercise: Exercise?
    var session: WorkoutSession?
    var timerTypeRaw: String
    var sortOrder: Int
    var notes: String?
    @Relationship(deleteRule: .cascade, inverse: \SetRecord.entry)
    var sets: [SetRecord]

    init(exercise: Exercise? = nil,
         session: WorkoutSession? = nil,
         timerType: TimerType = .reps,
         sortOrder: Int = 0,
         notes: String? = nil) {
        self.id           = UUID()
        self.exercise     = exercise
        self.session      = session
        self.timerTypeRaw = timerType.rawValue
        self.sortOrder    = sortOrder
        self.notes        = notes
        self.sets         = []
    }

    var timerType: TimerType {
        get { TimerType(rawValue: timerTypeRaw) ?? .reps }
        set { timerTypeRaw = newValue.rawValue }
    }

    var sortedSets: [SetRecord] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    var nextSetNumber: Int {
        (sets.map(\.setNumber).max() ?? 0) + 1
    }

    var bestSet: SetRecord? {
        sets.max { lhs, rhs in
            let lv = (lhs.weight ?? 0) * Double(lhs.reps ?? 0)
            let rv = (rhs.weight ?? 0) * Double(rhs.reps ?? 0)
            return lv < rv
        }
    }
}
