import SwiftUI

@main
struct WorkoutTrackerApp: App {
    @State private var planStore = WorkoutTrackerApp.makePlanStore()
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

    private static func makePlanStore() -> PlanStore {
        guard ProcessInfo.processInfo.arguments.contains("-ui-testing") else {
            return PlanStore()
        }
        // UI tests start from an empty week, kept apart from your real plan.
        let storage = JSONFileStorage<WeekPlan>.appSupport("ui-testing-week-plan.json")
        try? FileManager.default.removeItem(at: storage.url)
        return PlanStore(storage: storage)
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
