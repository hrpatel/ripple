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
    var currentTime: Date!

    override func setUp() {
        super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("reminders.json")
        store = ReminderStore(persistenceURL: tempURL)
        spy = SpyDelivery()
        currentTime = Date()
        engine = SchedulerEngine(store: store, delivery: spy, now: { self.currentTime })
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

    // MARK: - Task 3: Active hours, active days, disabled tests

    func test_recurring_respectsActiveHours() {
        // 08:00 on 2026-03-28 — before the 09:00–17:00 active window
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 28; c.hour = 8; c.minute = 0
        currentTime = Calendar.current.date(from: c)!

        let reminder = makeRecurring(intervalMinutes: 30, activeHoursStart: 540, activeHoursEnd: 1020)
        store.add(reminder)

        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 0)
    }

    func test_recurring_respectsActiveDays() {
        // 2026-03-28 is a Saturday — reminder only active Mon–Fri
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 28; c.hour = 10; c.minute = 0
        currentTime = Calendar.current.date(from: c)!

        let reminder = makeRecurring(intervalMinutes: 30, activeDays: [.mon, .tue, .wed, .thu, .fri])
        store.add(reminder)

        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 0)
    }

    func test_recurring_allDaysWhenActiveDaysNil() {
        // Same Saturday — activeDays nil means every day passes
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 28; c.hour = 10; c.minute = 0
        currentTime = Calendar.current.date(from: c)!

        let reminder = makeRecurring(intervalMinutes: 30, activeDays: nil)
        store.add(reminder)

        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 1)
    }

    // MARK: - Task 4: Snooze tests

    func test_recurring_skipsWhenSnoozed() {
        let reminder = makeRecurring(intervalMinutes: 30)
        store.add(reminder)
        engine.snooze(reminder.id)
        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 0)
    }

    func test_recurring_firesAfterSnoozeExpires() {
        let base = Date()
        currentTime = base

        let reminder = makeRecurring(intervalMinutes: 30)
        store.add(reminder)

        engine.snooze(reminder.id)
        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 0)

        // Advance 6 minutes — past the 5-minute snooze window
        currentTime = base.addingTimeInterval(6 * 60)
        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 1)
    }

    func test_disabled_neverFires() {
        var reminder = makeRecurring(intervalMinutes: 30)
        reminder.isEnabled = false
        store.add(reminder)
        engine.checkAndFire()
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
