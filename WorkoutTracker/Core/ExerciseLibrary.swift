import Foundation

/// The searchable set of exercises you can add to a day.
struct ExerciseLibrary {
    /// Every exercise, sorted by name.
    let exercises: [Exercise]
    /// Distinct primary muscles, sorted, for the filter bar.
    let muscleGroups: [String]
    private let byID: [String: Exercise]

    init(exercises: [Exercise]) {
        self.exercises = exercises.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        muscleGroups = Set(exercises.flatMap { $0.primaryMuscles.map { $0.lowercased() } })
            .sorted()
        byID = Dictionary(exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    init(data: Data) throws {
        try self.init(exercises: JSONDecoder().decode([Exercise].self, from: data))
    }

    /// Loads `exercises.json` from the app bundle.
    static func bundled(in bundle: Bundle = .main) throws -> ExerciseLibrary {
        guard let url = bundle.url(forResource: "exercises", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile, userInfo: [
                NSLocalizedDescriptionKey: "exercises.json is missing from the app bundle.",
            ])
        }
        return try ExerciseLibrary(data: Data(contentsOf: url))
    }

    func exercise(id: String) -> Exercise? {
        byID[id]
    }

    /// Exercises whose name, muscles or equipment match `searchText`,
    /// limited to `muscle` when one is chosen.
    func filtered(searchText: String, muscle: String? = nil) -> [Exercise] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return exercises.filter { exercise in
            if let muscle, !exercise.primaryMuscles.contains(where: { $0.caseInsensitiveCompare(muscle) == .orderedSame }) {
                return false
            }
            guard !query.isEmpty else { return true }
            let haystack = [exercise.name, exercise.equipment ?? ""]
                + exercise.primaryMuscles + exercise.secondaryMuscles
            return haystack.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    /// A readable explanation of why a dataset failed to load, naming the
    /// entry and field at fault where possible.
    static func describe(_ error: Error) -> String {
        guard let error = error as? DecodingError else {
            return error.localizedDescription
        }
        func path(_ codingPath: [CodingKey]) -> String {
            codingPath.map { key in
                key.intValue.map { "entry \($0 + 1)" } ?? key.stringValue
            }
            .joined(separator: " → ")
        }
        switch error {
        case let .keyNotFound(key, context):
            let location = path(context.codingPath)
            return "Missing \"\(key.stringValue)\"" + (location.isEmpty ? "." : " in \(location).")
        case let .typeMismatch(_, context), let .valueNotFound(_, context):
            return "Unexpected value at \(path(context.codingPath)): \(context.debugDescription)"
        case let .dataCorrupted(context):
            return context.debugDescription
        @unknown default:
            return error.localizedDescription
        }
    }
}
