import Foundation
import Testing
@testable import WorkoutTracker

struct PlanStorageTests {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("PlanStorageTests-\(UUID().uuidString)")

    var storage: JSONFileStorage<WeekPlan> {
        JSONFileStorage(url: directory.appendingPathComponent("week-plan.json"))
    }

    @Test func missingFileLoadsAsNothing() {
        #expect(storage.load() == nil)
    }

    @Test func savesAndLoads() throws {
        var plan = WeekPlan()
        plan[.saturday].title = "Long run"
        try storage.save(plan)
        #expect(storage.load() == plan)
    }

    @Test func unreadableFileIsMovedAsideNotLost() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: storage.url)

        #expect(storage.load() == nil)

        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        #expect(!files.contains("week-plan.json"))
        #expect(files.contains(where: { $0.hasPrefix("week-plan.unreadable-") && $0.hasSuffix(".json") }))
    }

    @Test func storeSavesEveryChange() throws {
        let store = PlanStore(storage: storage)
        #expect(store.plan == WeekPlan())

        store.plan[.monday].title = "Push"
        store.plan.add([Exercise(id: "bench", name: "Bench Press")], to: .monday)

        let reloaded = PlanStore(storage: storage)
        #expect(reloaded.plan[.monday].title == "Push")
        #expect(reloaded.plan[.monday].exercises.map(\.exerciseID) == ["bench"])
        #expect(store.saveError == nil)
    }
}
