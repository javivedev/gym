import SwiftUI

struct ExerciseDraft {
    var name = ""
    var machine = ""
    var sets = 4
    var reps = "10"
}

/// Hoja para crear o editar un ejercicio (máquina, series y reps).
struct ExerciseFormView: View {
    let title: String
    let onSave: (ExerciseDraft) -> Void
    @State private var draft: ExerciseDraft
    @Environment(\.dismiss) private var dismiss

    init(title: String, draft: ExerciseDraft = ExerciseDraft(), onSave: @escaping (ExerciseDraft) -> Void) {
        self.title = title
        self.onSave = onSave
        _draft = State(initialValue: draft)
    }

    private var isValid: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Ejercicio (p. ej. Press plano)", text: $draft.name)
                TextField("Máquina / material", text: $draft.machine)
                Stepper("Series: \(draft.sets)", value: $draft.sets, in: 1...10)
                LabeledContent("Repeticiones") {
                    TextField("10-12", text: $draft.reps)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        var clean = draft
                        clean.name = draft.name.trimmingCharacters(in: .whitespaces)
                        clean.machine = draft.machine.trimmingCharacters(in: .whitespaces)
                        onSave(clean)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
