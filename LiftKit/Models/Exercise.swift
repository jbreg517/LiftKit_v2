import Foundation
import SwiftData

enum Equipment: String, Codable, CaseIterable {
    case barbell    = "Barbell"
    case dumbbell   = "Dumbbell"
    case kettlebell = "Kettlebell"
    case machine    = "Machine"
    case cable      = "Cable"
    case bodyweight = "Bodyweight"
    case bands      = "Bands"
    case ball       = "Ball"
    case other      = "Other"

    var icon: String {
        switch self {
        case .barbell:    return "figure.strengthtraining.traditional"
        case .dumbbell:   return "dumbbell.fill"
        case .kettlebell: return "figure.core.training"
        case .machine:    return "gearshape.fill"
        case .cable:      return "cable.connector"
        case .bodyweight: return "figure.walk"
        case .bands:      return "minus.forwardslash.plus"
        case .ball:       return "circle.fill"
        case .other:      return "questionmark.circle.fill"
        }
    }
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case push    = "Push"
    case pull    = "Pull"
    case legs    = "Legs"
    case core    = "Core"
    case cardio  = "Cardio"
    case olympic = "Olympic"
    case custom  = "Custom"
}

enum WeightUnit: String, Codable, CaseIterable {
    case lb = "lb"
    case kg = "kg"
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var category: ExerciseCategory
    var equipment: Equipment?
    var notes: String?
    var isCustom: Bool
    var createdAt: Date

    init(name: String,
         category: ExerciseCategory = .custom,
         equipment: Equipment? = nil,
         notes: String? = nil,
         isCustom: Bool = false) {
        self.id        = UUID()
        self.name      = name
        self.category  = category
        self.equipment = equipment
        self.notes     = notes
        self.isCustom  = isCustom
        self.createdAt = Date()
    }
}
