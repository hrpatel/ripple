import Foundation

struct PersistenceManager {
    static let defaultURL: URL = {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = support.appendingPathComponent("Ripple", isDirectory: true)
        return dir.appendingPathComponent("reminders.json")
    }()

    static func load(from url: URL = defaultURL) -> [Reminder] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Reminder].self, from: data)
        } catch {
            print("PersistenceManager load error: \(error)")
            return []
        }
    }

    static func save(_ reminders: [Reminder], to url: URL = defaultURL) {
        do {
            let dir = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(reminders)
            try data.write(to: url, options: .atomic)
        } catch {
            print("PersistenceManager save error: \(error)")
        }
    }
}
