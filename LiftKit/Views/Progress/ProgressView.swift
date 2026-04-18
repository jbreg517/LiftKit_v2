import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.startedAt
    ) private var sessions: [WorkoutSession]

    @Query private var prs: [PersonalRecord]

    @State private var selectedExercise: String = ""
    @State private var timeRange: TimeRange = .allTime

    enum TimeRange: String, CaseIterable {
        case week = "1W"
        case month = "1M"
        case threeMonths = "3M"
        case year = "1Y"
        case allTime = "All"

        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            case .allTime: return nil
            }
        }
    }

    private var exerciseNames: [String] {
        let names = sessions.flatMap { s in
            s.entries.compactMap { $0.exercise?.name }
        }
        return Array(Set(names)).sorted()
    }

    private var totalWorkouts: Int { sessions.count }
    private var totalVolume: Double {
        sessions.reduce(0) { $0 + $1.totalVolume }
    }
    private var avgDuration: TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        return sessions.reduce(0) { $0 + $1.duration } / Double(sessions.count)
    }
    private var prCount: Int { prs.count }

    var body: some View {
        NavigationStack {
            List {
                overviewSection
                prSection
                chartSection
                weeklyVolumeSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Progress")
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        Section {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LKSpacing.md) {
                StatCard(icon: "figure.strengthtraining.traditional", value: "\(totalWorkouts)",
                         label: "Total Workouts", color: .blue)
                StatCard(icon: "scalemass.fill", value: String(format: "%.0f", totalVolume),
                         label: "Total Volume", color: .green)
                StatCard(icon: "clock.fill",
                         value: avgDuration > 0 ? formatDuration(avgDuration) : "—",
                         label: "Avg Duration", color: .orange)
                StatCard(icon: "trophy.fill", value: "\(prCount)",
                         label: "Personal Records", color: .yellow)
            }
        }
    }

    // MARK: - Personal Records

    private var prSection: some View {
        Section("Personal Records") {
            if prs.isEmpty {
                ContentUnavailableView(
                    "No PRs Yet",
                    systemImage: "trophy.fill",
                    description: Text("Complete workouts to start setting records.")
                )
            } else {
                let grouped = Dictionary(grouping: prs) { $0.exercise?.name ?? "Unknown" }
                ForEach(grouped.keys.sorted(), id: \.self) { name in
                    PRRow(name: name, records: grouped[name] ?? [], equipment: grouped[name]?.first?.exercise?.equipment)
                }
            }
        }
    }

    // MARK: - Exercise Chart

    private var chartSection: some View {
        Section("Exercise Progress") {
            if exerciseNames.isEmpty {
                Label("No Data", systemImage: "chart.line.downtrend.xyaxis")
                    .foregroundStyle(LKColors.Hex.textMuted)
            } else {
                Menu {
                    ForEach(exerciseNames, id: \.self) { name in
                        Button(name) { selectedExercise = name }
                    }
                } label: {
                    HStack {
                        Text(selectedExercise.isEmpty ? "Select Exercise" : selectedExercise)
                            .foregroundStyle(LKColors.Hex.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundStyle(LKColors.Hex.textSecondary)
                    }
                }
                .onAppear { if selectedExercise.isEmpty { selectedExercise = exerciseNames.first ?? "" } }

                if !selectedExercise.isEmpty {
                    Picker("Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)

                    let data = chartData(for: selectedExercise)
                    if data.isEmpty {
                        Label("No Data", systemImage: "chart.line.downtrend.xyaxis")
                            .foregroundStyle(LKColors.Hex.textMuted)
                    } else {
                        Chart(data, id: \.date) { point in
                            LineMark(x: .value("Date", point.date), y: .value("Weight", point.weight))
                                .foregroundStyle(Color.blue)
                                .interpolationMethod(.catmullRom)
                            PointMark(x: .value("Date", point.date), y: .value("Weight", point.weight))
                                .foregroundStyle(Color.blue)
                        }
                        .frame(height: 200)
                    }
                }
            }
        }
    }

    // MARK: - Weekly Volume

    private var weeklyVolumeSection: some View {
        Section("Weekly Volume") {
            let data = weeklyVolume()
            if data.isEmpty {
                Label("No Data", systemImage: "chart.bar")
                    .foregroundStyle(LKColors.Hex.textMuted)
            } else {
                Chart(data, id: \.week) { item in
                    BarMark(x: .value("Week", item.week, unit: .weekOfYear),
                            y: .value("Volume", item.volume))
                    .foregroundStyle(Color.blue.gradient.opacity(0.8))
                    .cornerRadius(4)
                }
                .chartYAxisLabel("Volume (lb)")
                .frame(height: 150)
            }
        }
    }

    // MARK: - Helpers

    struct ChartPoint { let date: Date; let weight: Double }
    struct WeekPoint { let week: Date; let volume: Double }

    private func chartData(for name: String) -> [ChartPoint] {
        let cutoff = timeRange.days.map { Date().addingTimeInterval(-Double($0) * 86400) }
        return sessions.compactMap { session -> ChartPoint? in
            guard let c = session.completedAt else { return nil }
            if let cutoff, c < cutoff { return nil }
            let entry = session.entries.first { $0.exercise?.name == name }
            guard let best = entry?.bestSet, let w = best.weight else { return nil }
            return ChartPoint(date: c, weight: w)
        }
    }

    private func weeklyVolume() -> [WeekPoint] {
        let cal = Calendar.current
        let cutoff = Date().addingTimeInterval(-8 * 7 * 86400)
        var byWeek: [Date: Double] = [:]
        for session in sessions {
            guard let c = session.completedAt, c >= cutoff else { continue }
            let week = cal.startOfWeek(for: c)
            byWeek[week, default: 0] += session.totalVolume
        }
        return byWeek.map { WeekPoint(week: $0.key, volume: $0.value) }
            .sorted { $0.week < $1.week }
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        return "\(m)m"
    }
}

// MARK: - StatCard

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: LKSpacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(LKColors.Hex.textPrimary)
            Text(label)
                .font(LKFont.caption)
                .foregroundStyle(LKColors.Hex.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(LKSpacing.md)
        .background(LKColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: LKRadius.large))
    }
}

// MARK: - PR Row

struct PRRow: View {
    let name: String
    let records: [PersonalRecord]
    let equipment: Equipment?

    var body: some View {
        VStack(alignment: .leading, spacing: LKSpacing.sm) {
            HStack(spacing: LKSpacing.sm) {
                Text(name).font(.headline).foregroundStyle(LKColors.Hex.textPrimary)
                if let eq = equipment {
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
            HStack(spacing: LKSpacing.lg) {
                ForEach(records.sorted { $0.typeRaw < $1.typeRaw }) { pr in
                    VStack(spacing: LKSpacing.xs) {
                        Image(systemName: "trophy.fill").foregroundStyle(Color.yellow)
                        Text(String(format: "%.0f", pr.value))
                            .font(LKFont.bodyBold)
                            .foregroundStyle(LKColors.Hex.textPrimary)
                        Text(pr.type.shortLabel)
                            .font(LKFont.caption)
                            .foregroundStyle(LKColors.Hex.textMuted)
                    }
                }
            }
        }
        .padding(.vertical, LKSpacing.xs)
    }
}

// MARK: - Calendar extension

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: comps) ?? date
    }
}
