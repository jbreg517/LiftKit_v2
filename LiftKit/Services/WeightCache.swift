import Foundation
import SwiftData

struct WeightCacheEntry {
    let weight: Double
    let unit: WeightUnit
    let equipment: Equipment?
}

final class WeightCache {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func lookup(exerciseName: String) -> WeightCacheEntry? {
        let lower = exerciseName.lowercased()
        let descriptor = FetchDescriptor<WorkoutEntry>(
            sortBy: [SortDescriptor(\.session?.startedAt, order: .reverse)]
        )
        guard let entries = try? modelContext.fetch(descriptor) else { return nil }
        for entry in entries {
            guard let name = entry.exercise?.name,
                  name.lowercased() == lower else { continue }
            let sets = entry.sortedSets
            if let lastSet = sets.last, let w = lastSet.weight {
                return WeightCacheEntry(
                    weight: w,
                    unit: lastSet.weightUnit,
                    equipment: entry.exercise?.equipment
                )
            }
        }
        return nil
    }

    func batchLookup(names: [String]) -> [String: WeightCacheEntry] {
        var result: [String: WeightCacheEntry] = [:]
        for name in names {
            if let entry = lookup(exerciseName: name) {
                result[name] = entry
            }
        }
        return result
    }
}
