import SwiftUI

@main
struct WorkoutTrackerApp: App {
    @State private var planStore = PlanStore()
    private let library: ExerciseLibrary
    private let libraryError: String?

    init() {
        do {
            library = try .bundled()
            libraryError = nil
        } catch {
            library = ExerciseLibrary(exercises: [])
            libraryError = ExerciseLibrary.describe(error)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(libraryError: libraryError)
                .environment(planStore)
                .environment(\.exerciseLibrary, library)
        }
    }
}

private struct ExerciseLibraryKey: EnvironmentKey {
    static let defaultValue = ExerciseLibrary(exercises: [])
}

extension EnvironmentValues {
    var exerciseLibrary: ExerciseLibrary {
        get { self[ExerciseLibraryKey.self] }
        set { self[ExerciseLibraryKey.self] = newValue }
    }
}

enum WeightUnit: String, CaseIterable, Identifiable {
    case pounds = "lb"
    case kilograms = "kg"

    var id: String { rawValue }

    /// The `@AppStorage` key for the chosen unit.
    static let storageKey = "weightUnit"
}
