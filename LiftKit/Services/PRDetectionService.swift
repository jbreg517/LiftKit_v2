import Foundation
import SwiftData

final class PRDetectionService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Returns newly achieved PR types for the given set/exercise pair.
    @discardableResult
    func evaluate(set: SetRecord, exercise: Exercise) -> [PRType] {
        var newPRs: [PRType] = []

        let descriptor = FetchDescriptor<PersonalRecord>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        let prsByType = Dictionary(grouping: existing.filter { $0.exercise?.id == exercise.id }) { $0.type }

        let checks: [(PRType, Double?)] = [
            (.maxWeight, set.weight),
            (.maxReps,   set.reps.map { Double($0) }),
            (.maxVolume, (set.weight != nil && set.reps != nil) ? set.weight! * Double(set.reps!) : nil)
        ]

        for (prType, value) in checks {
            guard let v = value else { continue }
            let existing = prsByType[prType]?.max(by: { $0.value < $1.value })
            if existing == nil || v > existing!.value {
                let pr = PersonalRecord(exercise: exercise, type: prType, value: v, setRecordId: set.id)
                modelContext.insert(pr)
                newPRs.append(prType)
            }
        }

        if !newPRs.isEmpty {
            try? modelContext.save()
        }

        return newPRs
    }
}
