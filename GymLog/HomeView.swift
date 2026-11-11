import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @AppStorage("restDays") private var restDays = 2
    @State private var month = Calendar.gym.startOfMonth(for: .now)
    @State private var path: [Date] = []
    @State private var showSettings = false

    private let cal = Calendar.gym

    private var trainedDays: Set<Date> {
        Set(workouts.filter(\.hasActivity).map { cal.startOfDay(for: $0.date) })
    }

    private var startedDays: Set<Date> {
        Set(workouts.map { cal.startOfDay(for: $0.date) })
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 20) {
                    StreakCard(trainedDays: trainedDays, restDays: restDays)
                        .onTapGesture { showSettings = true }

                    MonthCalendar(month: $month, trainedDays: trainedDays, startedDays: startedDays) { day in
                        path.append(day)
                    }

                    Button {
                        path.append(cal.startOfDay(for: .now))
                    } label: {
                        Label("Entrenar hoy", systemImage: "figure.strengthtraining.traditional")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .foregroundStyle(.black)
                }
                .padding()
            }
            .navigationTitle("Gym")
            .navigationDestination(for: Date.self) { DayView(date: $0) }
            .sheet(isPresented: $showSettings) { SettingsSheet() }
        }
    }
}

// MARK: - Racha

private struct StreakCard: View {
    let trainedDays: Set<Date>
    let restDays: Int
    private let cal = Calendar.gym

    var body: some View {
        let streak = Streak.current(trainedDays: trainedDays, restDays: restDays)
        let best = Streak.best(trainedDays: trainedDays, restDays: restDays)
        let week = trainedDays.filter { cal.isDate($0, equalTo: .now, toGranularity: .weekOfYear) }.count
        let month = trainedDays.filter { cal.isDate($0, equalTo: .now, toGranularity: .month) }.count

        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(streak > 0 ? Color.orange : Color.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(streak == 1 ? "día de racha" : "días de racha")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Stat(value: week, label: "esta semana")
                Stat(value: month, label: "este mes")
                Stat(value: best, label: "mejor racha")
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private struct Stat: View {
        let value: Int
        let label: String
        var body: some View {
            HStack(spacing: 4) {
                Text("\(value)").font(.subheadline.bold().monospacedDigit())
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Calendario

private struct MonthCalendar: View {
    @Binding var month: Date
    let trainedDays: Set<Date>
    let startedDays: Set<Date>
    let onSelect: (Date) -> Void

    private let cal = Calendar.gym
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var weekdaySymbols: [String] {
        cal.weekdaysInOrder.map { cal.veryShortStandaloneWeekdaySymbols[$0 - 1] }
    }

    private var cells: [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: month) else { return [] }
        let leading = (cal.component(.weekday, from: month) - cal.firstWeekday + 7) % 7
        let days = range.map { day -> Date? in cal.date(byAdding: .day, value: day - 1, to: month) }
        return Array(repeating: nil, count: leading) + days
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(month.formatted(.dateTime.month(.wide).year().locale(.spanish)).capitalized)
                    .font(.headline)
                Spacer()
                Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                    .padding(.horizontal, 8)
                Button { shift(1) } label: { Image(systemName: "chevron.right") }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        DayCell(
                            day: day,
                            trained: trainedDays.contains(day),
                            started: startedDays.contains(day),
                            isToday: cal.isDateInToday(day)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { onSelect(day) }
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private func shift(_ value: Int) {
        if let new = cal.date(byAdding: .month, value: value, to: month) {
            withAnimation(.snappy) { month = new }
        }
    }
}

private struct DayCell: View {
    let day: Date
    let trained: Bool
    let started: Bool
    let isToday: Bool

    var body: some View {
        Text("\(Calendar.gym.component(.day, from: day))")
            .font(.callout.weight(isToday || trained ? .bold : .regular).monospacedDigit())
            .foregroundStyle(trained ? Color.black : (day > .now ? Color.secondary : Color.primary))
            .frame(width: 38, height: 38)
            .background {
                if trained {
                    Circle().fill(Color.accentColor)
                } else if started {
                    Circle().strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 1.5, dash: [3]))
                }
            }
            .overlay {
                if isToday && !trained {
                    Circle().strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }
            .frame(height: 40)
    }
}

// MARK: - Ajustes

private struct SettingsSheet: View {
    @AppStorage("restDays") private var restDays = 2
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Descanso permitido: \(restDays) \(restDays == 1 ? "día" : "días")",
                            value: $restDays, in: 0...4)
                } footer: {
                    Text("Cuántos días seguidos puedes descansar sin perder la racha. Con 2, el fin de semana no la rompe.")
                }
            }
            .navigationTitle("Racha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Listo") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }
}
