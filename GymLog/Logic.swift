import Foundation

// MARK: - Racha

enum Streak {
    /// Días entrenados seguidos. Se permiten hasta `restDays` días de descanso
    /// entre entreno y entreno sin perder la racha (p. ej. 2 para el fin de semana).
    static func current(trainedDays: Set<Date>, restDays: Int, today: Date = .now, calendar cal: Calendar = .gym) -> Int {
        let todayStart = cal.startOfDay(for: today)
        let days = trainedDays.filter { $0 <= todayStart }.sorted(by: >)
        guard let last = days.first else { return 0 }

        // Si hoy aún no has ido, la racha sigue viva mientras no te pases de descansos.
        let restSinceLast = daysBetween(last, todayStart, cal) - 1
        if restSinceLast > restDays { return 0 }

        var count = 1
        var previous = last
        for day in days.dropFirst() {
            let rest = daysBetween(day, previous, cal) - 1
            if rest > restDays { break }
            count += 1
            previous = day
        }
        return count
    }

    /// La mejor racha de la historia.
    static func best(trainedDays: Set<Date>, restDays: Int, calendar cal: Calendar = .gym) -> Int {
        let days = trainedDays.sorted()
        guard var previous = days.first else { return 0 }
        var best = 1, run = 1
        for day in days.dropFirst() {
            run = daysBetween(previous, day, cal) - 1 > restDays ? 1 : run + 1
            best = max(best, run)
            previous = day
        }
        return best
    }

    private static func daysBetween(_ a: Date, _ b: Date, _ cal: Calendar) -> Int {
        cal.dateComponents([.day], from: a, to: b).day ?? 0
    }
}

// MARK: - Progresión

enum Progression {
    static let weightStep = 2.5

    /// Consejo simple de sobrecarga progresiva comparando con la última vez.
    static func suggestion(previous: ExerciseLog, targetSets: Int, targetReps: String) -> String? {
        let sets = previous.sortedSets
        guard !sets.isEmpty, let range = targetReps.repRange else { return nil }
        let topWeight = sets.map(\.weight).max() ?? 0

        let hitTop = sets.count >= targetSets && sets.allSatisfy { $0.reps >= range.high }
        if hitTop {
            return "Completaste todas las reps. Sube a \((topWeight + weightStep).kg) kg."
        }
        if sets.contains(where: { $0.reps < range.low }) {
            return "Mantén \(topWeight.kg) kg y busca llegar a \(range.low) reps en todas."
        }
        if sets.count < targetSets {
            return "Intenta completar las \(targetSets) series con \(topWeight.kg) kg."
        }
        return "Mismo peso, intenta 1 rep más por serie."
    }
}
