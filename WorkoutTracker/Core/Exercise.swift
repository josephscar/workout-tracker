import Foundation

/// One exercise from the dataset in `Resources/exercises.json`.
struct Exercise: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var primaryMuscles: [String] = []
    var secondaryMuscles: [String] = []
    var equipment: String?
    var category: String?
    var level: String?
    var instructions: [String] = []
    /// Suggested starting point when the exercise is added to a day.
    var defaultSets: Int?
    var defaultReps: Int?
    /// A video or article showing how to do the exercise.
    var link: URL?

    /// "Chest, Triceps" — the primary muscles, for list rows.
    var muscleSummary: String {
        primaryMuscles.map(\.capitalized).joined(separator: ", ")
    }
}

extension Exercise {
    // Datasets are hand-built, so decoding is forgiving: only `name` is
    // required, ids may be numbers or missing, and list fields may be a
    // single string.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        if let text = try? c.decodeIfPresent(String.self, forKey: .id) {
            id = text
        } else if let number = try? c.decodeIfPresent(Int.self, forKey: .id) {
            id = String(number)
        } else {
            id = Exercise.slug(name)
        }
        primaryMuscles = try c.decodeStringList(forKey: .primaryMuscles)
        secondaryMuscles = try c.decodeStringList(forKey: .secondaryMuscles)
        equipment = try c.decodeIfPresent(String.self, forKey: .equipment)
        category = try c.decodeIfPresent(String.self, forKey: .category)
        level = try c.decodeIfPresent(String.self, forKey: .level)
        instructions = try c.decodeStringList(forKey: .instructions)
        defaultSets = try c.decodeIfPresent(Int.self, forKey: .defaultSets)
        defaultReps = try c.decodeIfPresent(Int.self, forKey: .defaultReps)
        link = try? c.decodeIfPresent(URL.self, forKey: .link)
    }

    /// "Barbell Bench Press" → "barbell-bench-press".
    static func slug(_ name: String) -> String {
        name.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .joined(separator: "-")
    }
}

extension KeyedDecodingContainer {
    /// Decodes a list of strings that may also be given as one string.
    func decodeStringList(forKey key: Key) throws -> [String] {
        if let list = try? decodeIfPresent([String].self, forKey: key) {
            return list
        }
        if let single = try decodeIfPresent(String.self, forKey: key) {
            return [single]
        }
        return []
    }
}
