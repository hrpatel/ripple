import Foundation
import Observation

@Observable
final class ReminderStore {
    var reminders: [Reminder]
    private let persistenceURL: URL

    init(persistenceURL: URL = PersistenceManager.defaultURL) {
        self.persistenceURL = persistenceURL
        self.reminders = PersistenceManager.load(from: persistenceURL)
    }

    func add(_ reminder: Reminder) {
        reminders.append(reminder)
        save()
    }

    func update(_ reminder: Reminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index] = reminder
        save()
    }

    func delete(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        save()
    }

    private func save() {
        PersistenceManager.save(reminders, to: persistenceURL)
    }
}
