import SwiftUI

struct CreateWorkoutView: View {
    @Environment(WorkoutViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let onStart: () -> Void

    @State private var workoutName = ""
    @State private var exercises: [CreateExerciseItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Name") {
                    TextField("e.g., Push Day", text: $workoutName)
                        .font(.title3)
                        .foregroundStyle(LKColors.Hex.textPrimary)
                }

                Section("Exercises") {
                    ForEach($exercises) { $ex in
                        VStack(alignment: .leading, spacing: LKSpacing.xs) {
                            Text(ex.name.isEmpty ? "Exercise" : ex.name)
                                .font(LKFont.bodyBold)
                            Picker("Type", selection: $ex.timerType) {
                                ForEach(TimerType.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .pickerStyle(.segmented)
                            Stepper("Sets: \(ex.sets)", value: $ex.sets, in: 1...20)
                        }
                    }
                    .onDelete { exercises.remove(atOffsets: $0) }
                    .onMove { exercises.move(fromOffsets: $0, toOffset: $1) }

                    Button {
                        exercises.append(CreateExerciseItem())
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Start") {
                        startWorkout()
                    }
                    .fontWeight(.bold)
                    .disabled(exercises.isEmpty)
                }
            }
            .environment(\.editMode, .constant(.active))
        }
    }

    private func startWorkout() {
        vm.resetSetup(for: exercises.first?.timerType ?? .reps)
        vm.setupName = workoutName
        vm.setupExercises = exercises.map { ex in
            var setup = SetupExercise()
            setup.name = ex.name
            setup.sets = ex.sets
            return setup
        }
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            vm.startWorkout()
            onStart()
        }
    }
}

struct CreateExerciseItem: Identifiable {
    let id = UUID()
    var name: String = ""
    var timerType: TimerType = .reps
    var sets: Int = 3
}
