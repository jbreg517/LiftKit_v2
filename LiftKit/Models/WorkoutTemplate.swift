import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var createdAt: Date
    var lastUsedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]

    init(name: String) {
        self.id         = UUID()
        self.name       = name
        self.createdAt  = Date()
        self.lastUsedAt = nil
        self.exercises  = []
    }
}

@Model
final class TemplateExercise {
    var id: UUID
    var exercise: Exercise?
    var template: WorkoutTemplate?
    var timerTypeRaw: String
    var timerConfigData: Data?
    var targetSets: Int
    var targetReps: Int
    var sortOrder: Int

    init(exercise: Exercise? = nil,
         timerType: TimerType = .reps,
         timerConfig: TimerConfig? = nil,
         targetSets: Int = 3,
         targetReps: Int = 10,
         sortOrder: Int = 0) {
        self.id              = UUID()
        self.exercise        = exercise
        self.timerTypeRaw    = timerType.rawValue
        self.timerConfigData = try? JSONEncoder().encode(timerConfig)
        self.targetSets      = targetSets
        self.targetReps      = targetReps
        self.sortOrder       = sortOrder
    }

    var timerType: TimerType {
        get { TimerType(rawValue: timerTypeRaw) ?? .reps }
        set { timerTypeRaw = newValue.rawValue }
    }

    var timerConfig: TimerConfig? {
        guard let data = timerConfigData else { return nil }
        return try? JSONDecoder().decode(TimerConfig.self, from: data)
    }
}
