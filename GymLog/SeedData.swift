import Foundation
import SwiftData

/// Rutinas iniciales (sacadas de tu nota). Se pueden editar o borrar desde la pestaña Rutinas.
enum SeedData {
    private typealias Ex = (name: String, machine: String, sets: Int, reps: String)

    static func insert(into context: ModelContext) {
        let routines: [(String, String, Int, [Ex])] = [
            ("Lunes", "Pecho y tríceps", 2, [
                ("Press plano", "Banca", 4, "10-12"),
                ("Press inclinado con mancuerna", "Mancuernas", 4, "8-10"),
                ("Pec fly", "Pec deck", 4, "10"),
                ("Fondos o poleas pecho bajo", "Paralelas / polea", 4, "10"),
                ("Tríceps en polea", "Polea", 4, "10"),
                ("Tríceps en polea tras nuca", "Polea", 4, "10"),
                ("Tríceps en máquina nueva", "Máquina", 4, "10-12"),
            ]),
            ("Martes", "Espalda y bíceps", 3, [
                ("Jalón a pecho", "Polea alta", 4, "10"),
                ("Remo", "Poleas o cuerda", 4, "10-12"),
                ("Pec fly inverso", "Pec deck", 4, "10-12"),
                ("Jalón a cara", "Poleas", 4, "10"),
                ("Bíceps predicador", "Máquina predicador", 4, "10"),
                ("Bíceps mancuernas", "Mancuernas", 4, "10"),
                ("Bíceps polea", "Polea", 4, "10"),
            ]),
            ("Miércoles", "Pierna", 4, [
                ("Sentadilla / hack", "Hack squat", 4, "8-10"),
                ("Prensa", "Prensa", 3, "10-12"),
            ]),
        ]

        let base = Date.now
        for (index, (name, detail, weekday, exercises)) in routines.enumerated() {
            let routine = Routine(name: name, detail: detail, weekday: weekday,
                                  createdAt: base.addingTimeInterval(Double(index)))
            context.insert(routine)
            for (order, ex) in exercises.enumerated() {
                routine.exercises.append(
                    RoutineExercise(name: ex.name, machine: ex.machine, sets: ex.sets, reps: ex.reps, order: order)
                )
            }
        }
    }
}
