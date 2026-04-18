import SwiftUI
import SwiftData

struct WorkoutCalendarView: View {
    @Binding var navigateToSession: WorkoutSession?
    @Binding var selectedSchedule: WorkoutSchedule?

    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.startedAt
    ) private var sessions: [WorkoutSession]

    @Query private var schedules: [WorkoutSchedule]

    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date? = nil
    @State private var showMonthPicker = false

    private let calendar = Calendar.current

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: displayedMonth)
    }

    private var daysInMonth: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        let weekday = calendar.component(.weekday, from: monthStart) - calendar.firstWeekday
        let offset  = (weekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(d)
            }
        }
        return days
    }

    private func hasHistory(on date: Date) -> Bool {
        sessions.contains { session in
            guard let c = session.completedAt else { return false }
            return calendar.isDate(c, inSameDayAs: date)
        }
    }

    private func hasSchedule(on date: Date) -> Bool {
        schedules.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func historySessions(on date: Date) -> [WorkoutSession] {
        sessions.filter {
            guard let c = $0.completedAt else { return false }
            return calendar.isDate(c, inSameDayAs: date)
        }
    }

    private func scheduleItems(on date: Date) -> [WorkoutSchedule] {
        schedules.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        VStack(spacing: LKSpacing.sm) {
            monthHeader
            weekdayRow
            calendarGrid
            if let selected = selectedDate {
                selectedDateInfo(for: selected)
            }
        }
        .padding(LKSpacing.md)
        .background(LKColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: LKRadius.large))
        .sheet(isPresented: $showMonthPicker) {
            monthPickerSheet
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LKColors.Hex.textSecondary)
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Button {
                showMonthPicker = true
            } label: {
                Text(monthTitle)
                    .font(LKFont.bodyBold)
                    .foregroundStyle(LKColors.Hex.textPrimary)
            }

            Spacer()

            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LKColors.Hex.textSecondary)
            }
            .accessibilityLabel("Next month")
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { sym in
                Text(sym)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LKColors.Hex.textMuted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: cols, spacing: 4) {
            ForEach(daysInMonth.indices, id: \.self) { i in
                if let date = daysInMonth[i] {
                    DayCell(
                        date: date,
                        isToday: calendar.isDateInToday(date),
                        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                        hasHistory: hasHistory(on: date),
                        hasSchedule: hasSchedule(on: date)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = calendar.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast) ? nil : date
                        }
                    }
                } else {
                    Color.clear.frame(height: 36)
                }
            }
        }
    }

    @ViewBuilder
    private func selectedDateInfo(for date: Date) -> some View {
        let history = historySessions(on: date)
        let scheds   = scheduleItems(on: date)

        if !history.isEmpty || !scheds.isEmpty {
            VStack(alignment: .leading, spacing: LKSpacing.xs) {
                ForEach(history) { session in
                    Button {
                        navigateToSession = session
                    } label: {
                        HStack(spacing: LKSpacing.sm) {
                            Circle().fill(LKColors.Hex.accent).frame(width: 8, height: 8)
                            Text(session.name)
                                .font(LKFont.body)
                                .foregroundStyle(LKColors.Hex.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(LKFont.caption)
                                .foregroundStyle(LKColors.Hex.textMuted)
                        }
                    }
                }
                ForEach(scheds) { sched in
                    Button {
                        selectedSchedule = sched
                    } label: {
                        HStack(spacing: LKSpacing.sm) {
                            Circle().fill(LKColors.Hex.work).frame(width: 8, height: 8)
                            Text(sched.displayName)
                                .font(LKFont.body)
                                .foregroundStyle(LKColors.Hex.textPrimary)
                            Text("Planned")
                                .font(.caption2)
                                .foregroundStyle(LKColors.Hex.work)
                                .padding(.horizontal, LKSpacing.xs)
                                .padding(.vertical, 2)
                                .background(LKColors.Hex.work.opacity(0.15))
                                .clipShape(Capsule())
                            Spacer()
                        }
                    }
                }
            }
            .padding(.top, LKSpacing.xs)
        }
    }

    private var monthPickerSheet: some View {
        NavigationStack {
            DatePicker("Select Month", selection: $displayedMonth, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .tint(LKColors.Hex.accent)
                .padding()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showMonthPicker = false }
                    }
                }
        }
    }
}

struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let hasHistory: Bool
    let hasSchedule: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? LKColors.Hex.accent : LKColors.Hex.textPrimary)

                HStack(spacing: 2) {
                    if hasHistory {
                        Circle()
                            .fill(LKColors.Hex.accent)
                            .frame(width: 5, height: 5)
                            .accessibilityIdentifier("workoutDot")
                    }
                    if hasSchedule {
                        Circle()
                            .fill(LKColors.Hex.work)
                            .frame(width: 5, height: 5)
                            .accessibilityIdentifier("scheduleDot")
                    }
                }
                .frame(height: 5)
            }
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .background(
                isSelected
                    ? LKColors.Hex.accent.opacity(0.2)
                    : (isToday ? LKColors.Hex.surfaceElevated : Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: LKRadius.small))
        }
    }
}
