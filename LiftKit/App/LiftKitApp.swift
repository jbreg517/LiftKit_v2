import SwiftUI
import SwiftData
import UserNotifications

@main
struct LiftKitApp: App {
    @State private var workoutVM = WorkoutViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(workoutVM)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            Exercise.self,
            WorkoutSession.self,
            WorkoutEntry.self,
            SetRecord.self,
            PersonalRecord.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            UserProfile.self,
            WorkoutSchedule.self
        ])
    }

    init() {
        requestNotificationPermission()
        SoundManager.shared.configure()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
