import SwiftUI
import SwiftData

/// Lista de ejercicios del entreno, como la nota: marcas cada uno al terminar.
struct WorkoutView: View {
    @Bindable var workout: Workout
    @Environment(\.modelContext) private var context
    @State private var showAdd = false
    @State private var confirmDelete = false

    private var doneCount: Int { workout.exercises.filter(\.done).count }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(workout.routineName).font(.headline)
                        Spacer()
                        Text("\(doneCount)/\(workout.exercises.count)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: Double(doneCount), total: Double(max(workout.exercises.count, 1)))
                }
                .padding(.vertical, 4)
            }

            Section {
                ForEach(workout.sortedExercises) { log in
                    NavigationLink {
                        ExerciseLogView(log: log)
                    } label: {
                        ExerciseRow(log: log)
                    }
                }
                .onDelete(perform: delete)

                Button { showAdd = true } label: {
                    Label("Añadir ejercicio", systemImage: "plus")
                }
            }
        }
        .toolbar {
            Menu {
                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Eliminar entreno", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .sheet(isPresented: $showAdd) {
            ExerciseFormView(title: "Nuevo ejercicio") { draft in
                let next = (workout.exercises.map(\.order).max() ?? -1) + 1
                workout.exercises.append(
                    ExerciseLog(name: draft.name, machine: draft.machine,
                                targetSets: draft.sets, targetReps: draft.reps, order: next)
                )
            }
        }
        .confirmationDialog("¿Eliminar el entreno de este día?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Eliminar", role: .destructive) { context.delete(workout) }
        }
    }

    private func delete(_ offsets: IndexSet) {
        let items = workout.sortedExercises
        for index in offsets {
            let log = items[index]
            workout.exercises.removeAll { $0.persistentModelID == log.persistentModelID }
            context.delete(log)
        }
    }
}

private struct ExerciseRow: View {
    @Bindable var log: ExerciseLog

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) { log.done.toggle() }
            } label: {
                Image(systemName: log.done ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(log.done ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.borderless)
            .sensoryFeedback(.success, trigger: log.done) { _, new in new }

            VStack(alignment: .leading, spacing: 3) {
                Text(log.name)
                    .font(.body.weight(.medium))
                    .strikethrough(log.done, color: .secondary)
                Text([log.machine, "\(log.targetSets)×\(log.targetReps)"]
                        .filter { !$0.isEmpty }
                        .joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !log.sets.isEmpty {
                    Text(log.setsSummary)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tint)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
