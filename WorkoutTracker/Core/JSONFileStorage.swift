import Foundation

/// Saves a value as a JSON file. Used for the week plan (and later the meal plan).
struct JSONFileStorage<Value: Codable> {
    let url: URL

    /// A file in the app's Application Support directory.
    static func appSupport(_ filename: String) -> JSONFileStorage {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return JSONFileStorage(url: directory.appendingPathComponent(filename))
    }

    /// The saved value, or `nil` if nothing has been saved yet. A file that
    /// can't be decoded is moved aside rather than overwritten by the next save.
    func load() -> Value? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            let stamp = Int(Date().timeIntervalSince1970)
            let aside = url.deletingPathExtension()
                .appendingPathExtension("unreadable-\(stamp)")
                .appendingPathExtension(url.pathExtension)
            try? FileManager.default.moveItem(at: url, to: aside)
            return nil
        }
    }

    func save(_ value: Value) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: url, options: .atomic)
    }
}
