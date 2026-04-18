import Foundation
import SwiftData

@Model
final class WorkoutSchedule {
    var id: UUID
    var date: Date
    var template: WorkoutTemplate?
    var customName: String?
    var notes: String?
    var isCompleted: Bool

    init(date: Date,
         template: WorkoutTemplate? = nil,
         customName: String? = nil,
         notes: String? = nil) {
        self.id          = UUID()
        self.date        = date
        self.template    = template
        self.customName  = customName
        self.notes       = notes
        self.isCompleted = false
    }

    var displayName: String {
        template?.name ?? customName ?? "Workout"
    }
}
