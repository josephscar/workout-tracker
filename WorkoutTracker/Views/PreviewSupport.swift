import SwiftUI

extension PlanStore {
    /// A store with a few days filled in, saved to a temporary file.
    static func preview(library: ExerciseLibrary) -> PlanStore {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("preview-week-plan.json")
        try? FileManager.default.removeItem(at: url)
        let store = PlanStore(storage: JSONFileStorage(url: url))
        let exercises = library.exercises
        var plan = WeekPlan()
        plan[.monday].title = "Push"
        plan.add(Array(exercises.prefix(4)), to: .monday)
        plan[.wednesday].title = "Pull"
        plan.add(Array(exercises.dropFirst(4).prefix(3)), to: .wednesday)
        plan[.sunday].isRestDay = true
        store.plan = plan
        return store
    }
}

extension View {
    /// Supplies the bundled exercises and a sample plan to a preview.
    func previewEnvironment() -> some View {
        let library = (try? ExerciseLibrary.bundled()) ?? ExerciseLibrary(exercises: [])
        return environment(PlanStore.preview(library: library))
            .environment(\.exerciseLibrary, library)
    }
}
