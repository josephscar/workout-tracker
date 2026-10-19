import Foundation

/// An exercise scheduled on a day, with the targets you plan to hit.
struct PlannedExercise: Identifiable, Hashable, Codable {
    var id = UUID()
    /// The library exercise this came from.
    var exerciseID: String
    /// Copied from the library so the plan still reads well if the dataset changes.
    var name: String
    var sets: Int = 3
    var reps: Int = 10
    /// `nil` means bodyweight.
    var weight: Double?
    var notes: String = ""

    init(exercise: Exercise) {
        exerciseID = exercise.id
        name = exercise.name
        sets = exercise.defaultSets ?? 3
        reps = exercise.defaultReps ?? 10
    }

    init(id: UUID = UUID(), exerciseID: String, name: String, sets: Int = 3, reps: Int = 10, weight: Double? = nil, notes: String = "") {
        self.id = id
        self.exerciseID = exerciseID
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.notes = notes
    }

    // Saved plans must keep loading as fields are added, so everything but
    // the exercise itself falls back to a default.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        exerciseID = try c.decode(String.self, forKey: .exerciseID)
        name = try c.decode(String.self, forKey: .name)
        sets = try c.decodeIfPresent(Int.self, forKey: .sets) ?? 3
        reps = try c.decodeIfPresent(Int.self, forKey: .reps) ?? 10
        weight = try c.decodeIfPresent(Double.self, forKey: .weight)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}

/// Everything planned for one day of the week.
struct DayPlan: Identifiable, Hashable, Codable {
    let weekday: Weekday
    /// Optional label such as "Push Day".
    var title: String = ""
    var isRestDay = false
    var exercises: [PlannedExercise] = []

    var id: Weekday { weekday }

    init(weekday: Weekday, title: String = "", isRestDay: Bool = false, exercises: [PlannedExercise] = []) {
        self.weekday = weekday
        self.title = title
        self.isRestDay = isRestDay
        self.exercises = exercises
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        weekday = try c.decode(Weekday.self, forKey: .weekday)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        isRestDay = try c.decodeIfPresent(Bool.self, forKey: .isRestDay) ?? false
        exercises = try c.decodeIfPresent([PlannedExercise].self, forKey: .exercises) ?? []
    }
}

/// The weekly plan: one `DayPlan` for each weekday, Monday first.
struct WeekPlan: Hashable, Codable {
    private(set) var days: [DayPlan]

    init() {
        days = Weekday.allCases.map { DayPlan(weekday: $0) }
    }

    init(from decoder: Decoder) throws {
        // Slot days in by weekday so a missing or out-of-order day in the
        // saved file can't shift the rest of the week.
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        for day in try c.decodeIfPresent([DayPlan].self, forKey: .days) ?? [] {
            self[day.weekday] = day
        }
    }

    subscript(weekday: Weekday) -> DayPlan {
        get { days[weekday.rawValue - 1] }
        set {
            precondition(newValue.weekday == weekday, "DayPlan for \(newValue.weekday) stored under \(weekday)")
            days[weekday.rawValue - 1] = newValue
        }
    }

    /// Appends `exercises` to `day`, in order, with their default targets.
    mutating func add(_ exercises: [Exercise], to day: Weekday) {
        guard !exercises.isEmpty else { return }
        self[day].exercises.append(contentsOf: exercises.map(PlannedExercise.init(exercise:)))
        self[day].isRestDay = false
    }

    /// Replaces the planned exercise with the same id on `day`.
    mutating func update(_ planned: PlannedExercise, on day: Weekday) {
        guard let index = self[day].exercises.firstIndex(where: { $0.id == planned.id }) else { return }
        self[day].exercises[index] = planned
    }

    /// Makes `target` a copy of `source`, replacing whatever was planned there.
    mutating func copy(_ source: Weekday, to target: Weekday) {
        guard source != target else { return }
        let original = self[source]
        var copies = original.exercises
        for index in copies.indices {
            copies[index].id = UUID()
        }
        self[target] = DayPlan(weekday: target, title: original.title, isRestDay: original.isRestDay, exercises: copies)
    }

    mutating func clear(_ day: Weekday) {
        self[day] = DayPlan(weekday: day)
    }

    /// Days with at least one exercise that aren't rest days.
    var trainingDays: [DayPlan] {
        days.filter { !$0.isRestDay && !$0.exercises.isEmpty }
    }
}
