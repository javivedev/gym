import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Query(sort: \Routine.createdAt) private var routines: [Routine]
    @Environment(\.modelContext) private var context
    @State private var newRoutine: Routine?

    var body: some View {
        NavigationStack {
            List {
                ForEach(routines) { routine in
                    NavigationLink {
                        RoutineEditView(routine: routine)
                    } label: {
                        RoutineRow(routine: routine)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(routines[index]) }
                }
            }
            .overlay {
                if routines.isEmpty {
                    ContentUnavailableView("Sin rutinas", systemImage: "list.bullet.rectangle",
                                           description: Text("Toca + para crear tu primera rutina."))
                }
            }
            .navigationTitle("Rutinas")
            .toolbar {
                Button {
                    let routine = Routine(name: "")
                    context.insert(routine)
                    newRoutine = routine
                } label: {
                    Image(systemName: "plus")
                }
            }
            .navigationDestination(item: $newRoutine) { RoutineEditView(routine: $0) }
        }
    }
}

struct RoutineEditView: View {
    @Bindable var routine: Routine
    @State private var showAdd = false
    @State private var editing: RoutineExercise?
    @Environment(\.modelContext) private var context

    private let cal = Calendar.gym

    var body: some View {
        Form {
            Section {
                TextField("Nombre (p. ej. Lunes)", text: $routine.name)
                    .font(.headline)
                TextField("Grupo muscular (p. ej. Pecho)", text: $routine.detail)
                Picker("Día sugerido", selection: $routine.weekday) {
                    Text("Cualquiera").tag(Int?.none)
                    ForEach(cal.weekdaysInOrder, id: \.self) { day in
                        Text(cal.weekdayName(day)).tag(Int?.some(day))
                    }
                }
            }

            Section("Ejercicios") {
                ForEach(routine.sortedExercises) { ex in
                    Button { editing = ex } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(ex.name)
                            Text([ex.machine, "\(ex.sets)×\(ex.reps)"]
                                    .filter { !$0.isEmpty }
                                    .joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(Color.primary)
                }
                .onDelete(perform: delete)
                .onMove(perform: move)

                Button { showAdd = true } label: {
                    Label("Añadir ejercicio", systemImage: "plus")
                }
            }
        }
        .navigationTitle(routine.name.isEmpty ? "Nueva rutina" : routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(isPresented: $showAdd) {
            ExerciseFormView(title: "Nuevo ejercicio") { draft in
                let next = (routine.exercises.map(\.order).max() ?? -1) + 1
                routine.exercises.append(
                    RoutineExercise(name: draft.name, machine: draft.machine, sets: draft.sets, reps: draft.reps, order: next)
                )
            }
        }
        .sheet(item: $editing) { ex in
            ExerciseFormView(title: "Editar ejercicio",
                             draft: ExerciseDraft(name: ex.name, machine: ex.machine, sets: ex.sets, reps: ex.reps)) { draft in
                ex.name = draft.name
                ex.machine = draft.machine
                ex.sets = draft.sets
                ex.reps = draft.reps
            }
        }
        .onDisappear {
            if routine.name.trimmingCharacters(in: .whitespaces).isEmpty {
                routine.name = "Rutina"
            }
        }
    }

    private func delete(_ offsets: IndexSet) {
        let items = routine.sortedExercises
        for index in offsets {
            let ex = items[index]
            routine.exercises.removeAll { $0.persistentModelID == ex.persistentModelID }
            context.delete(ex)
        }
    }

    private func move(_ source: IndexSet, _ destination: Int) {
        var items = routine.sortedExercises
        items.move(fromOffsets: source, toOffset: destination)
        for (index, ex) in items.enumerated() { ex.order = index }
    }
}
