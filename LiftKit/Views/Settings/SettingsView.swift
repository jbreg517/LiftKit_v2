import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultRestSeconds") private var defaultRestSeconds: Double = 90
    @AppStorage("soundEnabled")    private var soundEnabled    = true
    @AppStorage("hapticsEnabled")  private var hapticsEnabled  = true

    @State private var showPrivacyPolicy = false
    @State private var showDisclaimer    = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Timer Defaults") {
                    VStack(alignment: .leading, spacing: LKSpacing.xs) {
                        Text("Default Rest: \(Int(defaultRestSeconds))s")
                            .foregroundStyle(LKColors.Hex.textPrimary)
                        Slider(value: $defaultRestSeconds, in: 30...300, step: 15)
                            .tint(LKColors.Hex.accent)
                    }
                }

                Section("Feedback") {
                    Toggle("Timer Sounds", isOn: $soundEnabled)
                    Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                }

                Section("Data") {
                    Button("Export Workout Data") {
                        // CSV export — not yet implemented
                    }
                    .foregroundStyle(LKColors.Hex.accent)
                }

                Section("About") {
                    LabeledContent("Version", value: version)
                    Button("Privacy Policy") { showPrivacyPolicy = true }
                        .foregroundStyle(LKColors.Hex.accent)
                    Button("Fitness Disclaimer") { showDisclaimer = true }
                        .foregroundStyle(LKColors.Hex.accent)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPrivacyPolicy) { privacySheet }
            .sheet(isPresented: $showDisclaimer) { disclaimerSheet }
        }
    }

    private var privacySheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LKSpacing.lg) {
                    Text("Privacy Policy")
                        .font(LKFont.title)
                        .foregroundStyle(LKColors.Hex.textPrimary)

                    Group {
                        Text("Data Collection")
                            .font(LKFont.heading)
                        Text("LiftKit is designed with your privacy in mind. We collect only the minimum information necessary to provide the app's functionality.\n\nAll workout data — including sessions, exercises, personal records, and templates — is stored exclusively on your device using Apple's SwiftData framework. This data never leaves your device unless you explicitly export it.\n\nIf you sign in using Apple ID or Google, we receive only the identifier provided by those platforms. We do not store passwords. We do not share your data with third parties. We do not use your data for advertising.")
                            .font(LKFont.body)
                            .foregroundStyle(LKColors.Hex.textSecondary)
                    }

                    Group {
                        Text("Analytics")
                            .font(LKFont.heading)
                        Text("LiftKit does not use any third-party analytics, tracking, or crash-reporting tools.")
                            .font(LKFont.body)
                            .foregroundStyle(LKColors.Hex.textSecondary)
                    }

                    Group {
                        Text("Contact")
                            .font(LKFont.heading)
                        Text("Questions about privacy? Contact us through the App Store listing.")
                            .font(LKFont.body)
                            .foregroundStyle(LKColors.Hex.textSecondary)
                    }
                }
                .padding(LKSpacing.lg)
            }
            .background(LKColors.Hex.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showPrivacyPolicy = false }
                }
            }
        }
    }

    private var disclaimerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LKSpacing.lg) {
                    Text("Fitness Disclaimer")
                        .font(LKFont.title)
                        .foregroundStyle(LKColors.Hex.textPrimary)

                    Text("LiftKit is a workout tracking tool intended for general fitness and informational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment.\n\nBefore beginning any new exercise program, we strongly recommend that you consult with a qualified healthcare provider, especially if you have any pre-existing medical conditions, injuries, or have been inactive for an extended period.\n\nExercise carries inherent risks. Always listen to your body. Stop any exercise that causes pain, dizziness, or discomfort and seek medical attention if needed.\n\nLiftKit and its developers accept no liability for any injury or adverse health effects resulting from use of this application.")
                        .font(LKFont.body)
                        .foregroundStyle(LKColors.Hex.textSecondary)
                }
                .padding(LKSpacing.lg)
            }
            .background(LKColors.Hex.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showDisclaimer = false }
                }
            }
        }
    }
}
