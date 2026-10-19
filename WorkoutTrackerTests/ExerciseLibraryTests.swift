import Foundation
import Testing
@testable import WorkoutTracker

struct ExerciseLibraryTests {
    @Test func bundledDatasetLoads() throws {
        let library = try ExerciseLibrary.bundled()
        #expect(!library.exercises.isEmpty)
        #expect(Set(library.exercises.map(\.id)).count == library.exercises.count, "exercise ids must be unique")
        #expect(library.exercises.allSatisfy { !$0.name.isEmpty })
        #expect(!library.muscleGroups.isEmpty)
    }

    @Test func decodesForgivingShapes() throws {
        let json = """
        [
          {"name": "Barbell Bench Press", "primaryMuscles": "Chest", "instructions": "Press it."},
          {"id": 42, "name": "Pull-Up", "primaryMuscles": ["lats"], "link": "https://example.com/pull-up"}
        ]
        """
        let library = try ExerciseLibrary(data: Data(json.utf8))

        let bench = try #require(library.exercise(id: "barbell-bench-press"))
        #expect(bench.primaryMuscles == ["Chest"])
        #expect(bench.instructions == ["Press it."])
        #expect(bench.secondaryMuscles.isEmpty)

        let pullUp = try #require(library.exercise(id: "42"))
        #expect(pullUp.link == URL(string: "https://example.com/pull-up"))
    }

    @Test func filtersBySearchAndMuscle() {
        let library = ExerciseLibrary(exercises: [
            Exercise(id: "bench", name: "Bench Press", primaryMuscles: ["chest"], equipment: "barbell"),
            Exercise(id: "fly", name: "Cable Fly", primaryMuscles: ["chest"], equipment: "cable"),
            Exercise(id: "curl", name: "Barbell Curl", primaryMuscles: ["biceps"], equipment: "barbell"),
        ])

        #expect(library.exercises.map(\.id) == ["curl", "bench", "fly"], "sorted by name")
        #expect(library.muscleGroups == ["biceps", "chest"])
        #expect(library.filtered(searchText: "").count == 3)
        #expect(library.filtered(searchText: "barbell").map(\.id) == ["curl", "bench"])
        #expect(library.filtered(searchText: "  CABLE ").map(\.id) == ["fly"])
        #expect(library.filtered(searchText: "", muscle: "Chest").map(\.id) == ["bench", "fly"])
        #expect(library.filtered(searchText: "barbell", muscle: "chest").map(\.id) == ["bench"])
    }

    @Test func explainsWhichEntryIsBroken() {
        let json = #"[{"name": "Squat"}, {"primaryMuscles": ["chest"]}]"#
        do {
            _ = try ExerciseLibrary(data: Data(json.utf8))
            Issue.record("Expected decoding to fail")
        } catch {
            let message = ExerciseLibrary.describe(error)
            #expect(message.contains("name"))
            #expect(message.contains("entry 2"))
        }
    }

    @Test func slugsNames() {
        #expect(Exercise.slug("Farmer's Carry") == "farmer-s-carry")
        #expect(Exercise.slug("  Push-Up (Wide) ") == "push-up-wide")
    }
}
