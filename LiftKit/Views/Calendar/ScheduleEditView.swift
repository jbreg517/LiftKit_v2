import SwiftUI
import SwiftData

struct ScheduleEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var templates: [WorkoutTemplate]

    @Bindable var schedule: WorkoutSchedule

    @State private var useCustomName = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker("Date", selection: $schedule.date, displayedComponents: .date)
                }

                Section("Workout") {
                    if !templates.isEmpty {
                        Picker("Template", selection: Binding(
                            get: { schedule.template },
                            set: { schedule.template = $0 }
                        )) {
                            Text("Custom").tag(Optional<WorkoutTemplate>.none)
                            ForEach(templates) { t in
                                Text(t.name).tag(Optional(t))
                            }
                        }
                    }
                    if schedule.template == nil {
                        TextField("Custom workout name", text: Binding(
                            get: { schedule.customName ?? "" },
                            set: { schedule.customName = $0.isEmpty ? nil : $0 }
                        ))
                    }
                }

                Section("Notes") {
                    TextField("Optional notes...", text: Binding(
                        get: { schedule.notes ?? "" },
                        set: { schedule.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }

                Section {
                    Button(role: .destructive) {
                        modelContext.delete(schedule)
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Scheduled Workout")
                        }
                    }
                }
            }
            .navigationTitle("Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}
