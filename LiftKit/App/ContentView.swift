import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(WorkoutViewModel.self) private var workoutVM
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            WorkoutHomeView()
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(LKColors.Hex.accent)
        .onAppear {
            workoutVM.configure(modelContext: modelContext)
            ExerciseLibrary.seed(in: modelContext)
        }
    }
}
