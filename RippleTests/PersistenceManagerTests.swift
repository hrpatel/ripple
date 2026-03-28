import XCTest
@testable import Ripple

final class PersistenceManagerTests: XCTestCase {
    var tempURL: URL!

    override func setUp() {
        super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("reminders.json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempURL.deletingLastPathComponent())
        super.tearDown()
    }

    func test_load_returnsEmptyArray_whenFileDoesNotExist() {
        let result = PersistenceManager.load(from: tempURL)
        XCTAssertEqual(result.count, 0)
    }

    func test_saveAndLoad_roundtrips() {
        let reminder = Reminder(
            id: UUID(),
            title: "Drink water",
            type: .recurring,
            intervalMinutes: 30,
            scheduledDate: nil,
            activeHoursStart: nil,
            activeHoursEnd: nil,
            activeDays: [.mon, .wed],
            isEnabled: true,
            delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
            snoozeEnabled: false
        )
        PersistenceManager.save([reminder], to: tempURL)
        let loaded = PersistenceManager.load(from: tempURL)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "Drink water")
        XCTAssertEqual(loaded.first?.intervalMinutes, 30)
        XCTAssertEqual(loaded.first?.activeDays, [.mon, .wed])
    }

    func test_save_overwritesPreviousData() {
        let first = Reminder(
            id: UUID(), title: "First", type: .oneTime,
            intervalMinutes: nil, scheduledDate: nil,
            activeHoursStart: nil, activeHoursEnd: nil,
            activeDays: [], isEnabled: true,
            delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
            snoozeEnabled: false
        )
        let second = Reminder(
            id: UUID(), title: "Second", type: .oneTime,
            intervalMinutes: nil, scheduledDate: nil,
            activeHoursStart: nil, activeHoursEnd: nil,
            activeDays: [], isEnabled: true,
            delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
            snoozeEnabled: false
        )
        PersistenceManager.save([first], to: tempURL)
        PersistenceManager.save([second], to: tempURL)
        let loaded = PersistenceManager.load(from: tempURL)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "Second")
    }
}
