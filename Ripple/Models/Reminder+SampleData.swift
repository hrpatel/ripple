#if DEBUG
import Foundation

extension Reminder {
    static let sampleRecurring = Reminder(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        title: "Stretch break",
        type: .recurring,
        intervalMinutes: 45,
        scheduledDate: nil,
        activeHoursStart: 540,   // 9am
        activeHoursEnd: 1020,    // 5pm
        activeDays: [.mon, .tue, .wed, .thu, .fri],
        isEnabled: true,
        delivery: DeliveryOptions(notification: true, sound: true, menubarIconFlash: false),
        snoozeDurationMinutes: 5
    )

    static let sampleOneTime = Reminder(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        title: "Team standup",
        type: .oneTime,
        intervalMinutes: nil,
        scheduledDate: Date().addingTimeInterval(3600),
        activeHoursStart: nil,
        activeHoursEnd: nil,
        activeDays: nil,
        isEnabled: true,
        delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
        snoozeDurationMinutes: nil
    )

    static let samplePaused = Reminder(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        title: "Drink water",
        type: .recurring,
        intervalMinutes: 30,
        scheduledDate: nil,
        activeHoursStart: nil,
        activeHoursEnd: nil,
        activeDays: nil,
        isEnabled: false,
        delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: true),
        snoozeDurationMinutes: nil
    )

    static let samples: [Reminder] = [sampleRecurring, sampleOneTime, samplePaused]
}

final class PreviewSchedulerEngine: SchedulerEngineProtocol {
    func nextFireDate(for reminder: Reminder) -> Date? {
        reminder.isEnabled ? Date().addingTimeInterval(900) : nil
    }
}

func previewStore(reminders: [Reminder] = Reminder.samples) -> ReminderStore {
    let store = ReminderStore(persistenceURL: URL(fileURLWithPath: "/dev/null"))
    store.reminders = reminders
    return store
}

func previewStoreBlocked() -> ReminderStore {
    let store = previewStore()
    store.notificationsBlocked = true
    return store
}
#endif
