import Foundation

final class SchedulerEngine {
    private let store: ReminderStore
    private let delivery: DeliveryManagerProtocol
    private let now: () -> Date
    private var timer: Timer?
    private var lastFired: [UUID: Date] = [:]
    private var snoozedUntil: [UUID: Date] = [:]

    init(
        store: ReminderStore,
        delivery: DeliveryManagerProtocol,
        now: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.delivery = delivery
        self.now = now
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkAndFire()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func snooze(_ id: UUID) {
        snoozedUntil[id] = now().addingTimeInterval(5 * 60)
    }

    func checkAndFire() {
        let current = now()
        snoozedUntil = snoozedUntil.filter { $0.value > current }

        for reminder in store.reminders {
            guard reminder.isEnabled else { continue }
            guard snoozedUntil[reminder.id] == nil else { continue }

            switch reminder.type {
            case .recurring:
                guard shouldFireRecurring(reminder, at: current) else { continue }
                lastFired[reminder.id] = current
                delivery.deliver(reminder)
            case .oneTime:
                guard let scheduledDate = reminder.scheduledDate, current >= scheduledDate else { continue }
                var updated = reminder
                updated.isEnabled = false
                store.update(updated)
                delivery.deliver(reminder)
            }
        }
    }

    func nextFireDate(for reminder: Reminder) -> Date? {
        guard reminder.isEnabled else { return nil }

        switch reminder.type {
        case .recurring:
            guard let interval = reminder.intervalMinutes else { return nil }
            if let last = lastFired[reminder.id] {
                return last.addingTimeInterval(Double(interval) * 60)
            }
            return now()
        case .oneTime:
            return reminder.scheduledDate
        }
    }

    private func shouldFireRecurring(_ reminder: Reminder, at date: Date) -> Bool {
        guard let intervalMinutes = reminder.intervalMinutes else { return false }

        // Active days check
        if let activeDays = reminder.activeDays {
            let calWeekday = Calendar.current.component(.weekday, from: date)
            guard activeDays.contains(weekdayFromCalendar(calWeekday)) else { return false }
        }

        // Active hours check (assumes start <= end, no overnight ranges)
        if let start = reminder.activeHoursStart, let end = reminder.activeHoursEnd {
            let h = Calendar.current.component(.hour, from: date)
            let m = Calendar.current.component(.minute, from: date)
            let mins = h * 60 + m
            guard mins >= start && mins <= end else { return false }
        }

        // Interval elapsed check
        if let last = lastFired[reminder.id] {
            let elapsedMinutes = date.timeIntervalSince(last) / 60
            guard elapsedMinutes >= Double(intervalMinutes) else { return false }
        }

        return true
    }

    private func weekdayFromCalendar(_ calendarWeekday: Int) -> Weekday {
        // Calendar.weekday: Sun=1, Mon=2, Tue=3, Wed=4, Thu=5, Fri=6, Sat=7
        // Weekday enum:     Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7
        switch calendarWeekday {
        case 1: return .sun
        case 2: return .mon
        case 3: return .tue
        case 4: return .wed
        case 5: return .thu
        case 6: return .fri
        default: return .sat
        }
    }
}
