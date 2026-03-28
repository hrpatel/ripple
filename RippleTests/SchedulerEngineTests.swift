import XCTest
@testable import Ripple

// MARK: - Spy

final class SpyDelivery: DeliveryManagerProtocol {
    var delivered: [Reminder] = []
    func deliver(_ reminder: Reminder) {
        delivered.append(reminder)
    }
}

// MARK: - Tests

final class SchedulerEngineTests: XCTestCase {
    var tempURL: URL!
    var store: ReminderStore!
    var spy: SpyDelivery!
    var engine: SchedulerEngine!

    override func setUp() {
        super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("reminders.json")
        store = ReminderStore(persistenceURL: tempURL)
        spy = SpyDelivery()
        engine = SchedulerEngine(store: store, delivery: spy)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempURL.deletingLastPathComponent())
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeRecurring(
        intervalMinutes: Int = 30,
        activeHoursStart: Int? = nil,
        activeHoursEnd: Int? = nil,
        activeDays: Set<Weekday>? = nil
    ) -> Reminder {
        Reminder(
            id: UUID(),
            title: "Test Recurring",
            type: .recurring,
            intervalMinutes: intervalMinutes,
            scheduledDate: nil,
            activeHoursStart: activeHoursStart,
            activeHoursEnd: activeHoursEnd,
            activeDays: activeDays,
            isEnabled: true,
            delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
            snoozeEnabled: false
        )
    }

    // MARK: - Task 2: Recurring interval tests

    func test_recurring_firesWhenDue() {
        let reminder = makeRecurring(intervalMinutes: 30)
        store.add(reminder)
        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 1)
    }

    func test_recurring_doesNotFireBeforeInterval() {
        let reminder = makeRecurring(intervalMinutes: 30)
        store.add(reminder)
        engine.checkAndFire()   // first fire — sets lastFired
        spy.delivered.removeAll()
        engine.checkAndFire()   // immediately again — interval not elapsed
        XCTAssertEqual(spy.delivered.count, 0)
    }

    private func makeOneTime(scheduledDate: Date) -> Reminder {
        Reminder(
            id: UUID(),
            title: "Test One-Time",
            type: .oneTime,
            intervalMinutes: nil,
            scheduledDate: scheduledDate,
            activeHoursStart: nil,
            activeHoursEnd: nil,
            activeDays: nil,
            isEnabled: true,
            delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
            snoozeEnabled: false
        )
    }
}
