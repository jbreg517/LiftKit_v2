import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(WorkoutViewModel.self) private var vm
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    ) private var sessions: [WorkoutSession]

    @State private var showActiveWorkout = false

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Workouts Yet",
                        systemImage: "figure.strengthtraining.traditional",
                        description: Text("Complete a workout and it will appear here.")
                    )
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink(destination: WorkoutDetailView(session: session)) {
                                SessionRow(session: session)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(session)
                                    try? modelContext.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button {
                                    vm.repeatWorkout(session)
                                    showActiveWorkout = true
                                } label: {
                                    Label("Do Again", systemImage: "arrow.counterclockwise")
                                }
                                Button(role: .destructive) {
                                    modelContext.delete(session)
                                    try? modelContext.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(LKColors.Hex.background)
                }
            }
            .navigationTitle("History")
            .background(LKColors.Hex.background)
        }
        .fullScreenCover(isPresented: $showActiveWorkout) {
            ActiveWorkoutView()
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: LKSpacing.xs) {
            HStack(spacing: LKSpacing.sm) {
                Text(session.name)
                    .font(.headline)
                    .foregroundStyle(LKColors.Hex.textPrimary)
                if let type = session.timerType {
                    Text(type.rawValue)
                        .font(.caption2)
                        .foregroundStyle(LKColors.Hex.textSecondary)
                        .padding(.horizontal, LKSpacing.xs)
                        .padding(.vertical, 2)
                        .background(Color(UIColor.systemGray5))
                        .clipShape(Capsule())
                }
            }
            HStack(spacing: LKSpacing.xs) {
                Text(session.startedAt, style: .date)
                Text("·")
                Text(session.formattedDuration)
                Text("·")
                Text("\(session.entries.count) exercises")
            }
            .font(.subheadline)
            .foregroundStyle(LKColors.Hex.textSecondary)
        }
        .padding(.vertical, LKSpacing.xs)
    }
}

// MARK: - Workout Detail View

struct WorkoutDetailView: View {
    @Environment(WorkoutViewModel.self) private var vm
    let session: WorkoutSession
    @State private var showActiveWorkout = false

    var body: some View {
        List {
            summarySection
            ForEach(session.entries.sorted { $0.sortOrder < $1.sortOrder }) { entry in
                entrySection(entry: entry)
            }
            if let notes = session.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .foregroundStyle(LKColors.Hex.textSecondary)
                }
            }
            Section {
                Button {
                    vm.repeatWorkout(session)
                    showActiveWorkout = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Do Again")
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(LKColors.Hex.accent)
                }
            }
        }
        .navigationTitle(session.name)
        .listStyle(.insetGrouped)
        .fullScreenCover(isPresented: $showActiveWorkout) {
            ActiveWorkoutView()
        }
    }

    private var summarySection: some View {
        Section("Summary") {
            LabeledContent("Duration", value: session.formattedDuration)
            LabeledContent("Exercises", value: "\(session.entries.count)")
            LabeledContent("Total Volume", value: String(format: "%.0f lb", session.totalVolume))
            if let type = session.timerType {
                LabeledContent("Timer Type", value: type.rawValue)
            }
        }
    }

    private func entrySection(entry: WorkoutEntry) -> some View {
        Section {
            ForEach(entry.sortedSets) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .foregroundStyle(LKColors.Hex.textSecondary)
                    Spacer()
                    if let w = set.weight {
                        Text(String(format: "%.0f %@", w, set.weightUnit.rawValue))
                    }
                    Text("×")
                    if let r = set.reps {
                        Text("\(r)")
                    }
                    if let pw = set.plannedWeight, pw != (set.weight ?? 0) {
                        Text("(\(Int(pw)))")
                            .font(LKFont.caption)
                            .foregroundStyle(LKColors.Hex.textSecondary)
                    }
                }
            }
        } header: {
            HStack(spacing: LKSpacing.xs) {
                Text(entry.exercise?.name ?? "Workout")
                    .font(.headline)
                if let eq = entry.exercise?.equipment {
                    HStack(spacing: LKSpacing.xs) {
                        Image(systemName: eq.icon)
                        Text(eq.rawValue)
                    }
                    .font(.caption2)
                    .padding(.horizontal, LKSpacing.xs)
                    .padding(.vertical, 2)
                    .background(Color(UIColor.systemGray5))
                    .clipShape(Capsule())
                }
            }
        }
    }
}
