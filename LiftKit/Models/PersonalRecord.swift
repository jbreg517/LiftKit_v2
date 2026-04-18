import Foundation
import SwiftData

enum PRType: String, Codable, CaseIterable {
    case maxWeight = "maxWeight"
    case maxReps   = "maxReps"
    case maxVolume = "maxVolume"

    var label: String {
        switch self {
        case .maxWeight: return "Max Weight"
        case .maxReps:   return "Max Reps"
        case .maxVolume: return "Max Volume"
        }
    }

    var shortLabel: String {
        switch self {
        case .maxWeight: return "lb"
        case .maxReps:   return "reps"
        case .maxVolume: return "lb vol"
        }
    }
}

@Model
final class PersonalRecord {
    var id: UUID
    var exercise: Exercise?
    var typeRaw: String
    var value: Double
    var achievedAt: Date
    var setRecordId: UUID?

    init(exercise: Exercise? = nil,
         type: PRType,
         value: Double,
         setRecordId: UUID? = nil) {
        self.id          = UUID()
        self.exercise    = exercise
        self.typeRaw     = type.rawValue
        self.value       = value
        self.achievedAt  = Date()
        self.setRecordId = setRecordId
    }

    var type: PRType {
        get { PRType(rawValue: typeRaw) ?? .maxWeight }
        set { typeRaw = newValue.rawValue }
    }
}
