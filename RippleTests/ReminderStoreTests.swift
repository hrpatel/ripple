import XCTest
@testable import Ripple

final class ReminderStoreTests: XCTestCase {
    var tempURL: URL!
    var store: ReminderStore!

    override func setUp() {
        super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("reminders.json")
        store = ReminderStore(persistenceURL: tempURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempURL.deletingLastPathComponent())
        super.tearDown()
    }

    func test_init_loadsEmptyWhenNoFile() {
        XCTAssertEqual(store.reminders.count, 0)
    }

    func test_add_appendsReminder() {
        let r = makeReminder(title: "Stand up")
        store.add(r)
        XCTAssertEqual(store.reminders.count, 1)
        XCTAssertEqual(store.reminders.first?.title, "Stand up")
    }

    func test_add_persistsReminder() {
        let r = makeReminder(title: "Hydrate")
        store.add(r)
        let loaded = PersistenceManager.load(from: tempURL)
        XCTAssertEqual(loaded.first?.title, "Hydrate")
    }

    func test_delete_removesReminder() {
        let r = makeReminder(title: "Break")
        store.add(r)
        store.delete(r)
        XCTAssertEqual(store.reminders.count, 0)
    }

    func test_update_replacesReminder() {
        var r = makeReminder(title: "Original")
        store.add(r)
        r.title = "Updated"
        store.update(r)
        XCTAssertEqual(store.reminders.first?.title, "Updated")
    }

    // MARK: - Helpers

    private func makeReminder(title: String) -> Reminder {
        Reminder(
            id: UUID(),
            title: title,
            type: .recurring,
            intervalMinutes: 30,
            scheduledDate: nil,
            activeHoursStart: nil,
            activeHoursEnd: nil,
            activeDays: [.mon],
            isEnabled: true,
            delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
            snoozeEnabled: false
        )
    }
}
