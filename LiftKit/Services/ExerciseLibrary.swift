import Foundation
import SwiftData

final class ExerciseLibrary {
    static func seed(in context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { !$0.isCustom })
        guard let existing = try? context.fetch(descriptor), existing.isEmpty else { return }

        let exercises: [(String, ExerciseCategory, Equipment?)] = [
            // Push
            ("Bench Press", .push, .barbell),
            ("Incline Bench Press", .push, .barbell),
            ("Overhead Press", .push, .barbell),
            ("Push Up", .push, .bodyweight),
            ("Dumbbell Shoulder Press", .push, .dumbbell),
            ("Dumbbell Fly", .push, .dumbbell),
            ("Cable Chest Fly", .push, .cable),
            ("Tricep Pushdown", .push, .cable),
            ("Tricep Dip", .push, .bodyweight),
            ("Skull Crusher", .push, .barbell),
            // Pull
            ("Pull Up", .pull, .bodyweight),
            ("Barbell Row", .pull, .barbell),
            ("Lat Pulldown", .pull, .cable),
            ("Seated Cable Row", .pull, .cable),
            ("Dumbbell Row", .pull, .dumbbell),
            ("Face Pull", .pull, .cable),
            ("Bicep Curl", .pull, .dumbbell),
            ("Hammer Curl", .pull, .dumbbell),
            ("EZ Bar Curl", .pull, .barbell),
            ("Chin Up", .pull, .bodyweight),
            // Legs
            ("Squat", .legs, .barbell),
            ("Deadlift", .legs, .barbell),
            ("Romanian Deadlift", .legs, .barbell),
            ("Leg Press", .legs, .machine),
            ("Leg Extension", .legs, .machine),
            ("Leg Curl", .legs, .machine),
            ("Lunge", .legs, .dumbbell),
            ("Bulgarian Split Squat", .legs, .dumbbell),
            ("Calf Raise", .legs, .machine),
            ("Hip Thrust", .legs, .barbell),
            // Core
            ("Plank", .core, .bodyweight),
            ("Crunch", .core, .bodyweight),
            ("Sit Up", .core, .bodyweight),
            ("Russian Twist", .core, .bodyweight),
            ("Leg Raise", .core, .bodyweight),
            ("Ab Wheel Rollout", .core, .bodyweight),
            ("Cable Crunch", .core, .cable),
            ("Side Plank", .core, .bodyweight),
            // Cardio
            ("Running", .cardio, nil),
            ("Cycling", .cardio, nil),
            ("Rowing", .cardio, .machine),
            ("Jump Rope", .cardio, nil),
            ("Box Jump", .cardio, .bodyweight),
            ("Burpee", .cardio, .bodyweight),
            ("Jumping Jack", .cardio, .bodyweight),
            // Olympic
            ("Clean and Jerk", .olympic, .barbell),
            ("Snatch", .olympic, .barbell),
            ("Power Clean", .olympic, .barbell),
            ("Hang Clean", .olympic, .barbell),
            ("Thruster", .olympic, .barbell),
        ]

        for (name, category, equipment) in exercises {
            let exercise = Exercise(name: name, category: category, equipment: equipment, isCustom: false)
            context.insert(exercise)
        }

        try? context.save()
    }
}
