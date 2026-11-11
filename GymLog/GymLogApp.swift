import SwiftUI
import SwiftData

@main
struct GymLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Routine.self, RoutineExercise.self, Workout.self, ExerciseLog.self, SetLog.self])
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Entrenos", systemImage: "calendar") }
            RoutinesView()
                .tabItem { Label("Rutinas", systemImage: "list.bullet.rectangle") }
        }
        .task {
            if !didSeed {
                SeedData.insert(into: context)
                didSeed = true
            }
        }
    }
}
