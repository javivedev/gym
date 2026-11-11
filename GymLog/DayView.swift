import SwiftUI
import SwiftData

/// Un día del calendario: si ya hay entreno lo muestra; si no, eliges rutina.
struct DayView: View {
    let date: Date
    @Query private var workouts: [Workout]
    @Query(sort: \Routine.createdAt) private var routines: [Routine]
    @Environment(\.modelContext) private var context

    init(date: Date) {
        let cal = Calendar.gym
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        self.date = start
        _workouts = Query(filter: #Predicate<Workout> { $0.date >= start && $0.date < end },
                          sort: \Workout.date)
    }

    private var title: String {
        date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated).locale(.spanish)).capitalized
    }

    private var weekday: Int { Calendar.gym.component(.weekday, from: date) }

    var body: some View {
        Group {
            if let workout = workouts.first {
                WorkoutView(workout: workout)
            } else {
                routinePicker
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var routinePicker: some View {
        let suggested = routines.filter { $0.weekday == weekday }
        let others = routines.filter { $0.weekday != weekday }

        return List {
            if !suggested.isEmpty {
                Section("Te toca hoy") {
                    ForEach(suggested) { routine in
                        Button { start(routine) } label: { RoutineRow(routine: routine) }
                            .tint(Color.primary)
                    }
                }
            }
            if !others.isEmpty {
                Section(suggested.isEmpty ? "Elige tu rutina" : "Otras rutinas") {
                    ForEach(others) { routine in
                        Button { start(routine) } label: { RoutineRow(routine: routine) }
                            .tint(Color.primary)
                    }
                }
            }
            Section {
                Button { start(nil) } label: {
                    Label("Entreno libre (añadir ejercicios a mano)", systemImage: "square.and.pencil")
                }
            } footer: {
                if routines.isEmpty {
                    Text("Crea rutinas en la pestaña Rutinas para empezar más rápido.")
                }
            }
        }
    }

    private func start(_ routine: Routine?) {
        let workout = Workout(date: date, routineName: routine.map { routineTitle($0) } ?? "Entreno libre")
        context.insert(workout)
        for ex in routine?.sortedExercises ?? [] {
            workout.exercises.append(
                ExerciseLog(name: ex.name, machine: ex.machine, targetSets: ex.sets, targetReps: ex.reps, order: ex.order)
            )
        }
    }

    private func routineTitle(_ routine: Routine) -> String {
        routine.detail.isEmpty ? routine.name : "\(routine.name) · \(routine.detail)"
    }
}

struct RoutineRow: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(routine.name).font(.headline)
            Text([routine.detail, "\(routine.exercises.count) ejercicios"]
                    .filter { !$0.isEmpty }
                    .joined(separator: " · "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
