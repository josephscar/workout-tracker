import Foundation
import Observation

/// Owns the week plan and saves every change to disk.
@Observable
final class PlanStore {
    private var storedPlan: WeekPlan
    private let storage: JSONFileStorage<WeekPlan>

    /// Set when a save fails, so the UI can tell you.
    var saveError: String? = nil

    var plan: WeekPlan {
        get { storedPlan }
        set {
            storedPlan = newValue
            do {
                try storage.save(newValue)
            } catch {
                saveError = error.localizedDescription
            }
        }
    }

    init(storage: JSONFileStorage<WeekPlan> = .appSupport("week-plan.json")) {
        self.storage = storage
        storedPlan = storage.load() ?? WeekPlan()
    }
}
