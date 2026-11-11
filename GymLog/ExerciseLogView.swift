import SwiftUI
import SwiftData
import UIKit

/// Registro de un ejercicio: qué hiciste la última vez y tus series de hoy.
struct ExerciseLogView: View {
    @Bindable var log: ExerciseLog
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allLogs: [ExerciseLog]

    /// El mismo ejercicio en el entreno anterior más reciente (con series registradas).
    private var previous: ExerciseLog? {
        guard let date = log.workout?.date else { return nil }
        let key = log.name.normalizedKey
        return allLogs
            .filter { $0.name.normalizedKey == key && !$0.sets.isEmpty && ($0.workout?.date ?? .distantFuture) < date }
            .max { ($0.workout?.date ?? .distantPast) < ($1.workout?.date ?? .distantPast) }
    }

    var body: some View {
        let prev = previous

        List {
            Section {
                TextField("Ejercicio", text: $log.name)
                    .font(.headline)
                TextField("Máquina / material", text: $log.machine)
                Stepper("Series objetivo: \(log.targetSets)", value: $log.targetSets, in: 1...10)
                LabeledContent("Reps objetivo") {
                    TextField("10-12", text: $log.targetReps)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                }
            }

            if let prev {
                Section {
                    ForEach(Array(prev.sortedSets.enumerated()), id: \.element.persistentModelID) { index, set in
                        HStack {
                            Text("Serie \(index + 1)").foregroundStyle(.secondary)
                            Spacer()
                            Text("\(set.weight.kg) kg × \(set.reps)").monospacedDigit()
                        }
                    }
                    if let tip = Progression.suggestion(previous: prev, targetSets: log.targetSets, targetReps: log.targetReps) {
                        Label(tip, systemImage: "arrow.up.right.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.tint)
                    }
                } header: {
                    Text("Última vez · \(lastDateText(prev))")
                }
            }

            Section {
                ForEach(Array(log.sortedSets.enumerated()), id: \.element.persistentModelID) { index, set in
                    SetRow(set: set, number: index + 1)
                }
                .onDelete(perform: deleteSets)

                Button(action: { addSet(previous: prev) }) {
                    Label("Añadir serie", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Hoy")
            } footer: {
                if let prev, !log.sets.isEmpty {
                    volumeComparison(today: log.volume, before: prev.volume)
                }
            }

            Section {
                Button {
                    log.done.toggle()
                    if log.done { dismiss() }
                } label: {
                    Label(log.done ? "Marcar como pendiente" : "Ejercicio terminado",
                          systemImage: log.done ? "arrow.uturn.backward" : "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
            }
        }
        .navigationTitle(log.name)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") { hideKeyboard() }
            }
        }
        .onDisappear { hideKeyboard() }
    }

    // MARK: Acciones

    private func addSet(previous prev: ExerciseLog?) {
        let today = log.sortedSets
        let weight: Double
        let reps: Int

        if let last = today.last {
            // Repite tu última serie de hoy.
            weight = last.weight
            reps = last.reps
        } else if let prevSet = prev?.sortedSets.first {
            // Primera serie: parte de lo que hiciste la última vez.
            weight = prevSet.weight
            reps = prevSet.reps
        } else {
            weight = 0
            reps = log.targetReps.repRange?.low ?? 10
        }

        let next = (log.sets.map(\.order).max() ?? -1) + 1
        withAnimation {
            log.sets.append(SetLog(reps: reps, weight: weight, order: next))
        }
    }

    private func deleteSets(_ offsets: IndexSet) {
        let items = log.sortedSets
        for index in offsets {
            let set = items[index]
            log.sets.removeAll { $0.persistentModelID == set.persistentModelID }
            context.delete(set)
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: Helpers de UI

    private func lastDateText(_ prev: ExerciseLog) -> String {
        guard let date = prev.workout?.date else { return "" }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(.spanish))
    }

    @ViewBuilder
    private func volumeComparison(today: Double, before: Double) -> some View {
        let diff = today - before
        HStack(spacing: 4) {
            Text("Volumen \(today.kg) kg")
            if diff != 0 {
                Text("(\(diff > 0 ? "+" : "")\(diff.kg) vs última vez)")
                    .foregroundStyle(diff > 0 ? Color.green : Color.secondary)
            }
        }
        .font(.caption.monospacedDigit())
    }
}

/// Una fila de serie: peso y repeticiones editables.
private struct SetRow: View {
    @Bindable var set: SetLog
    let number: Int

    var body: some View {
        HStack(spacing: 8) {
            Text("\(number)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 22, alignment: .leading)

            TextField("0", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.body.monospacedDigit())
                .frame(width: 64)
            Text("kg").foregroundStyle(.secondary)

            Spacer()

            Stepper(value: $set.reps, in: 0...100) {
                Text("\(set.reps) reps")
                    .font(.body.monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .fixedSize()
        }
    }
}
