import Foundation
import SwiftData

// MARK: - Plantillas (rutinas)

/// Una rutina reutilizable, p. ej. "Lunes · Pecho".
@Model
final class Routine {
    var name: String
    var detail: String
    /// Día de la semana sugerido (1 = domingo … 7 = sábado, como `Calendar`). `nil` = cualquier día.
    var weekday: Int?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine)
    var exercises: [RoutineExercise] = []

    init(name: String, detail: String = "", weekday: Int? = nil, createdAt: Date = .now) {
        self.name = name
        self.detail = detail
        self.weekday = weekday
        self.createdAt = createdAt
    }

    var sortedExercises: [RoutineExercise] {
        exercises.sorted { $0.order < $1.order }
    }
}

/// Un ejercicio dentro de una rutina (lo que tienes planeado hacer).
@Model
final class RoutineExercise {
    var name: String
    var machine: String
    var sets: Int
    /// Texto libre: "10", "10-12", "8-10"…
    var reps: String
    var order: Int
    var routine: Routine?

    init(name: String, machine: String = "", sets: Int = 4, reps: String = "10", order: Int = 0) {
        self.name = name
        self.machine = machine
        self.sets = sets
        self.reps = reps
        self.order = order
    }
}

// MARK: - Registro (lo que realmente hiciste)

/// Un entrenamiento en un día concreto.
@Model
final class Workout {
    /// Siempre el inicio del día.
    var date: Date
    var routineName: String

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.workout)
    var exercises: [ExerciseLog] = []

    init(date: Date, routineName: String) {
        self.date = date
        self.routineName = routineName
    }

    var sortedExercises: [ExerciseLog] {
        exercises.sorted { $0.order < $1.order }
    }

    /// Cuenta para la racha si has marcado algo o registrado alguna serie.
    var hasActivity: Bool {
        exercises.contains { $0.done || !$0.sets.isEmpty }
    }
}

/// Un ejercicio dentro de un entrenamiento.
@Model
final class ExerciseLog {
    var name: String
    var machine: String
    var targetSets: Int
    var targetReps: String
    var order: Int
    var done: Bool
    var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.exercise)
    var sets: [SetLog] = []

    init(name: String, machine: String = "", targetSets: Int = 4, targetReps: String = "10", order: Int = 0) {
        self.name = name
        self.machine = machine
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.order = order
        self.done = false
    }

    var sortedSets: [SetLog] {
        sets.sorted { $0.order < $1.order }
    }

    /// Volumen total (kg × reps).
    var volume: Double {
        sets.reduce(0) { $0 + $1.weight * Double($1.reps) }
    }

    /// "40×10 · 42.5×8"
    var setsSummary: String {
        sortedSets.map { "\($0.weight.kg)×\($0.reps)" }.joined(separator: " · ")
    }
}

/// Una serie: peso y repeticiones.
@Model
final class SetLog {
    var reps: Int
    var weight: Double
    var order: Int
    var exercise: ExerciseLog?

    init(reps: Int, weight: Double, order: Int) {
        self.reps = reps
        self.weight = weight
        self.order = order
    }
}

// MARK: - Helpers

extension Double {
    /// 40 → "40", 42.5 → "42.5"
    var kg: String {
        formatted(.number.precision(.fractionLength(0...1)))
    }
}

extension String {
    /// Para comparar ejercicios ignorando mayúsculas, tildes y espacios.
    var normalizedKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// "10-12" → (10, 12); "10" → (10, 10)
    var repRange: (low: Int, high: Int)? {
        let numbers = split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard let first = numbers.first else { return nil }
        return (first, numbers.last ?? first)
    }
}

extension Calendar {
    /// Calendario en español con la semana empezando en lunes.
    static var gym: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "es_ES")
        cal.firstWeekday = 2
        cal.timeZone = .current
        return cal
    }

    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? startOfDay(for: date)
    }

    /// Días de la semana empezando en lunes (valores de `Calendar`: 2, 3, … 7, 1).
    var weekdaysInOrder: [Int] {
        (0..<7).map { (firstWeekday - 1 + $0) % 7 + 1 }
    }

    func weekdayName(_ weekday: Int) -> String {
        weekdaySymbols[weekday - 1].capitalized
    }
}

extension Locale {
    static let spanish = Locale(identifier: "es_ES")
}
