import Foundation
import SwiftData

@Model
final class SetRecord {
    var id: UUID
    var setNumber: Int
    var weight: Double?
    var weightUnitRaw: String
    var reps: Int?
    var duration: TimeInterval?
    var completedAt: Date
    var notes: String?
    var plannedWeight: Double?
    var plannedReps: Int?
    var entry: WorkoutEntry?

    init(setNumber: Int,
         weight: Double? = nil,
         weightUnit: WeightUnit = .lb,
         reps: Int? = nil,
         duration: TimeInterval? = nil,
         notes: String? = nil,
         plannedWeight: Double? = nil,
         plannedReps: Int? = nil) {
        self.id             = UUID()
        self.setNumber      = setNumber
        self.weight         = weight
        self.weightUnitRaw  = weightUnit.rawValue
        self.reps           = reps
        self.duration       = duration
        self.completedAt    = Date()
        self.notes          = notes
        self.plannedWeight  = plannedWeight
        self.plannedReps    = plannedReps
    }

    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .lb }
        set { weightUnitRaw = newValue.rawValue }
    }

    var volume: Double {
        guard let w = weight, let r = reps else { return 0 }
        return w * Double(r)
    }
}
