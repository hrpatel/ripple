# Green Dot, Configurable Snooze, Overnight Hours — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a green dot indicator on the menubar icon when reminders are active, make snooze duration configurable per-reminder, and support overnight active hour ranges (e.g. 10pm–6am).

**Architecture:** Three independent features sharing a model change. The model change (`snoozeEnabled` → `snoozeDurationMinutes`) propagates through SchedulerEngine, DeliveryManager, and form/detail views. The green dot is driven by observation of `ReminderStore.reminders` in `AppDelegate`. Overnight hours is a logic change in `shouldFireRecurring` with adjusted weekday resolution.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit (NSStatusItem, NSStatusBarButton), UserNotifications, Observation framework, XCTest.

---

## File Map

| Status | Path | Responsibility |
|--------|------|----------------|
| Modify | `Ripple/Models/Reminder.swift` | Replace `snoozeEnabled: Bool` with `snoozeDurationMinutes: Int?` |
| Modify | `Ripple/Scheduling/SchedulerEngine.swift` | `snooze(_:duration:)`, overnight hours logic |
| Modify | `Ripple/Scheduling/DeliveryManager.swift` | Per-duration categories, `onSnooze` signature, flash restore callback |
| Modify | `Ripple/AppDelegate.swift` | `updateMenubarIcon()`, observation, flash restore, snooze wiring |
| Modify | `Ripple/Extensions/Reminder+Formatting.swift` | `snoozeLabel` helper |
| Modify | `Ripple/Views/ReminderFormView.swift` | Snooze picker, remove `start >= end` validation |
| Modify | `Ripple/Views/ReminderDetailView.swift` | Show snooze duration |
| Modify | `RippleTests/SchedulerEngineTests.swift` | Overnight, snooze duration tests |
| Modify | `RippleTests/ReminderStoreTests.swift` | Update `makeReminder` helper |
| Modify | `RippleTests/PersistenceManagerTests.swift` | Update test reminders |
| Modify | `README.md` | Update feature descriptions |
| Modify | `CHANGELOG.md` | Already populated |

---

### Task 1: Update data model — replace `snoozeEnabled` with `snoozeDurationMinutes`

**Files:**
- Modify: `Ripple/Models/Reminder.swift`

- [ ] **Step 1: Replace the snooze field**

Open `Ripple/Models/Reminder.swift`. Replace the `snoozeEnabled` property:

```swift
struct Reminder: Identifiable, Codable {
    var id: UUID
    var title: String
    var type: ReminderType
    var intervalMinutes: Int?
    var scheduledDate: Date?
    var activeHoursStart: Int?  // minutes since midnight, e.g. 540 = 09:00
    var activeHoursEnd: Int?    // minutes since midnight, e.g. 1020 = 17:00
    var activeDays: Set<Weekday>?
    var isEnabled: Bool
    var delivery: DeliveryOptions
    var snoozeDurationMinutes: Int?  // nil = snooze off, e.g. 5 = snooze 5 min
}
```

- [ ] **Step 2: Build to see all compile errors**

Press **⌘B**.
Expected: Multiple compile errors across the codebase where `snoozeEnabled` is referenced. This confirms all the call sites we need to update.

- [ ] **Step 3: Commit the model change**

```bash
git add Ripple/Models/Reminder.swift
git commit -m "feat: replace snoozeEnabled with snoozeDurationMinutes on Reminder"
```

---

### Task 2: Fix test helpers to use new model field

**Files:**
- Modify: `RippleTests/SchedulerEngineTests.swift`
- Modify: `RippleTests/ReminderStoreTests.swift`
- Modify: `RippleTests/PersistenceManagerTests.swift`

- [ ] **Step 1: Update SchedulerEngineTests helpers**

In `RippleTests/SchedulerEngineTests.swift`, update both helper methods.

In `makeRecurring`, replace `snoozeEnabled: false` with `snoozeDurationMinutes: nil`:

```swift
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
            snoozeDurationMinutes: nil
        )
    }
```

In `makeOneTime`, replace `snoozeEnabled: false` with `snoozeDurationMinutes: nil`:

```swift
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
            snoozeDurationMinutes: nil
        )
    }
```

- [ ] **Step 2: Update ReminderStoreTests helper**

In `RippleTests/ReminderStoreTests.swift`, update `makeReminder`. Replace `snoozeEnabled: false` with `snoozeDurationMinutes: nil`:

```swift
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
            snoozeDurationMinutes: nil
        )
    }
```

- [ ] **Step 3: Update PersistenceManagerTests reminders**

In `RippleTests/PersistenceManagerTests.swift`, replace every `snoozeEnabled: false` with `snoozeDurationMinutes: nil`. There are three occurrences — one in `test_saveAndLoad_roundtrips` and two in `test_save_overwritesPreviousData`.

- [ ] **Step 4: Commit**

```bash
git add RippleTests/SchedulerEngineTests.swift RippleTests/ReminderStoreTests.swift RippleTests/PersistenceManagerTests.swift
git commit -m "fix: update test helpers for snoozeDurationMinutes model change"
```

---

### Task 3: Update SchedulerEngine — snooze duration + overnight hours (TDD)

**Files:**
- Modify: `RippleTests/SchedulerEngineTests.swift`
- Modify: `Ripple/Scheduling/SchedulerEngine.swift`

- [ ] **Step 1: Update existing snooze tests for new signature**

In `RippleTests/SchedulerEngineTests.swift`, update the two existing snooze tests to use `snooze(_:duration:)`.

Replace `test_recurring_skipsWhenSnoozed`:

```swift
    func test_recurring_skipsWhenSnoozed() {
        let reminder = makeRecurring(intervalMinutes: 30)
        store.add(reminder)
        engine.snooze(reminder.id, duration: 5)
        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 0)
    }
```

Replace `test_recurring_firesAfterSnoozeExpires`:

```swift
    func test_recurring_firesAfterSnoozeExpires() {
        let base = Date()
        currentTime = base

        let reminder = makeRecurring(intervalMinutes: 30)
        store.add(reminder)

        engine.snooze(reminder.id, duration: 5)
        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 0)

        // Advance 6 minutes — past the 5-minute snooze window
        currentTime = base.addingTimeInterval(6 * 60)
        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 1)
    }
```

- [ ] **Step 2: Add new test for configurable snooze duration**

Add this test after the existing snooze tests:

```swift
    func test_recurring_snoozeDurationIsConfigurable() {
        let base = Date()
        currentTime = base

        let reminder = makeRecurring(intervalMinutes: 30)
        store.add(reminder)

        engine.snooze(reminder.id, duration: 10)

        // Advance 6 minutes — past 5 min but within 10 min snooze
        currentTime = base.addingTimeInterval(6 * 60)
        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 0)

        // Advance to 11 minutes — past the 10-minute snooze
        currentTime = base.addingTimeInterval(11 * 60)
        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 1)
    }
```

- [ ] **Step 3: Add overnight hours tests**

Add these tests in a new MARK section after the next fire date tests:

```swift
    // MARK: - Overnight active hours tests

    func test_recurring_overnightHours_firesBeforeMidnight() {
        // Friday 11pm — within 10pm–6am window
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 27; c.hour = 23; c.minute = 0
        currentTime = Calendar.current.date(from: c)!

        let reminder = makeRecurring(
            intervalMinutes: 30,
            activeHoursStart: 1320,  // 10pm = 22*60
            activeHoursEnd: 360      // 6am = 6*60
        )
        store.add(reminder)

        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 1)
    }

    func test_recurring_overnightHours_firesAfterMidnight() {
        // Saturday 2am — within 10pm–6am window (started Friday night)
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 28; c.hour = 2; c.minute = 0
        currentTime = Calendar.current.date(from: c)!

        let reminder = makeRecurring(
            intervalMinutes: 30,
            activeHoursStart: 1320,  // 10pm
            activeHoursEnd: 360      // 6am
        )
        store.add(reminder)

        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 1)
    }

    func test_recurring_overnightHours_doesNotFireOutsideWindow() {
        // Saturday 8am — outside the 10pm–6am window
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 28; c.hour = 8; c.minute = 0
        currentTime = Calendar.current.date(from: c)!

        let reminder = makeRecurring(
            intervalMinutes: 30,
            activeHoursStart: 1320,  // 10pm
            activeHoursEnd: 360      // 6am
        )
        store.add(reminder)

        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 0)
    }

    func test_recurring_overnightHours_activeDays_checksStartDay() {
        // Saturday 2am — the overnight window started Friday night
        // Active days Mon–Fri: Friday is active, so this should fire
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 28; c.hour = 2; c.minute = 0
        currentTime = Calendar.current.date(from: c)!

        let reminder = makeRecurring(
            intervalMinutes: 30,
            activeHoursStart: 1320,  // 10pm
            activeHoursEnd: 360,     // 6am
            activeDays: [.mon, .tue, .wed, .thu, .fri]
        )
        store.add(reminder)

        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 1)
    }

    func test_recurring_overnightHours_activeDays_rejectsInactiveStartDay() {
        // Sunday 2am — the overnight window started Saturday night
        // Active days Mon–Fri: Saturday is NOT active, so this should NOT fire
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 29; c.hour = 2; c.minute = 0
        currentTime = Calendar.current.date(from: c)!

        let reminder = makeRecurring(
            intervalMinutes: 30,
            activeHoursStart: 1320,  // 10pm
            activeHoursEnd: 360,     // 6am
            activeDays: [.mon, .tue, .wed, .thu, .fri]
        )
        store.add(reminder)

        engine.checkAndFire()
        XCTAssertEqual(spy.delivered.count, 0)
    }
```

- [ ] **Step 4: Run tests to confirm they fail**

Press **⌘U**.
Expected: Multiple failures — `snooze(_:duration:)` doesn't exist yet, and the overnight tests fail because the active hours check doesn't handle `start > end`.

- [ ] **Step 5: Update `snooze` method in SchedulerEngine**

In `Ripple/Scheduling/SchedulerEngine.swift`, replace the `snooze` method:

```swift
    func snooze(_ id: UUID, duration: Int) {
        snoozedUntil[id] = now().addingTimeInterval(Double(duration) * 60)
    }
```

- [ ] **Step 6: Update `shouldFireRecurring` for overnight hours and active day logic**

Replace the entire `shouldFireRecurring` method in `Ripple/Scheduling/SchedulerEngine.swift`:

```swift
    private func shouldFireRecurring(_ reminder: Reminder, at date: Date) -> Bool {
        guard let intervalMinutes = reminder.intervalMinutes else { return false }

        let calWeekday = Calendar.current.component(.weekday, from: date)

        // Active hours check (supports overnight ranges where start > end)
        if let start = reminder.activeHoursStart, let end = reminder.activeHoursEnd {
            let h = Calendar.current.component(.hour, from: date)
            let m = Calendar.current.component(.minute, from: date)
            let mins = h * 60 + m

            if start <= end {
                // Daytime range: e.g. 9am–5pm
                guard mins >= start && mins <= end else { return false }
            } else {
                // Overnight range: e.g. 10pm–6am
                guard mins >= start || mins <= end else { return false }
            }

            // Active days check — for overnight ranges in the after-midnight portion,
            // check the previous day (the day the window started)
            if let activeDays = reminder.activeDays {
                let isOvernight = start > end
                let isAfterMidnight = isOvernight && mins <= end
                let dayToCheck: Int
                if isAfterMidnight {
                    // Wrap: Sun(1) -> Sat(7), Mon(2) -> Sun(1), etc.
                    dayToCheck = calWeekday == 1 ? 7 : calWeekday - 1
                } else {
                    dayToCheck = calWeekday
                }
                guard activeDays.contains(weekdayFromCalendar(dayToCheck)) else { return false }
            }
        } else {
            // No active hours set — just check active days against current day
            if let activeDays = reminder.activeDays {
                guard activeDays.contains(weekdayFromCalendar(calWeekday)) else { return false }
            }
        }

        // Interval elapsed check
        if let last = lastFired[reminder.id] {
            let elapsedMinutes = date.timeIntervalSince(last) / 60
            guard elapsedMinutes >= Double(intervalMinutes) else { return false }
        }

        return true
    }
```

- [ ] **Step 7: Run tests to confirm all pass**

Press **⌘U**.
Expected: All tests pass — existing tests plus new snooze duration and overnight tests.

- [ ] **Step 8: Commit**

```bash
git add Ripple/Scheduling/SchedulerEngine.swift RippleTests/SchedulerEngineTests.swift
git commit -m "feat: add configurable snooze duration and overnight active hours to SchedulerEngine"
```

---

### Task 4: Update DeliveryManager — per-duration categories, snooze callback, flash restore

**Files:**
- Modify: `Ripple/Scheduling/DeliveryManager.swift`

- [ ] **Step 1: Replace the entire DeliveryManager.swift**

Replace the contents of `Ripple/Scheduling/DeliveryManager.swift` with:

```swift
import AppKit
import UserNotifications

protocol DeliveryManagerProtocol {
    func deliver(_ reminder: Reminder)
}

final class DeliveryManager: NSObject, DeliveryManagerProtocol {
    private weak var statusButton: NSStatusBarButton?
    private let onSnooze: (UUID, Int) -> Void
    private let onNotificationsBlocked: () -> Void
    private let onFlashComplete: () -> Void
    private let snoozePresets = [1, 5, 10, 15, 30]

    init(
        statusButton: NSStatusBarButton?,
        onSnooze: @escaping (UUID, Int) -> Void,
        onNotificationsBlocked: @escaping () -> Void,
        onFlashComplete: @escaping () -> Void
    ) {
        self.statusButton = statusButton
        self.onSnooze = onSnooze
        self.onNotificationsBlocked = onNotificationsBlocked
        self.onFlashComplete = onFlashComplete
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        var categories = Set<UNNotificationCategory>()
        for minutes in snoozePresets {
            let action = UNNotificationAction(
                identifier: "SNOOZE",
                title: "Snooze \(minutes) min"
            )
            let category = UNNotificationCategory(
                identifier: "REMINDER_\(minutes)",
                actions: [action],
                intentIdentifiers: []
            )
            categories.insert(category)
        }
        UNUserNotificationCenter.current().setNotificationCategories(categories)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func deliver(_ reminder: Reminder) {
        if reminder.delivery.notification {
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                if settings.authorizationStatus == .denied {
                    self?.onNotificationsBlocked()
                } else {
                    self?.sendNotification(for: reminder)
                }
            }
        }
        if reminder.delivery.sound {
            NSSound(named: .init("Glass"))?.play()
        }
        if reminder.delivery.menubarIconFlash {
            flashMenubarIcon()
        }
    }

    private func sendNotification(for reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        if let duration = reminder.snoozeDurationMinutes {
            content.categoryIdentifier = "REMINDER_\(duration)"
        }
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func flashMenubarIcon() {
        var count = 0
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            count += 1
            let filled = count % 2 == 0
            self?.statusButton?.image = NSImage(
                systemSymbolName: filled ? "bell.fill" : "bell",
                accessibilityDescription: nil
            )
            if count >= 8 {
                timer.invalidate()
                self?.onFlashComplete()
            }
        }
    }
}

extension DeliveryManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "SNOOZE",
           let id = UUID(uuidString: response.notification.request.identifier) {
            // Extract duration from categoryIdentifier (e.g. "REMINDER_5" → 5)
            let category = response.notification.request.content.categoryIdentifier
            let duration = Int(category.replacingOccurrences(of: "REMINDER_", with: "")) ?? 5
            onSnooze(id, duration)
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
```

- [ ] **Step 2: Build to confirm it compiles**

Press **⌘B**.
Expected: Compile error in `AppDelegate.swift` — missing `onFlashComplete` parameter and `snooze` signature mismatch. This is expected and fixed in Task 5.

- [ ] **Step 3: Commit**

```bash
git add Ripple/Scheduling/DeliveryManager.swift
git commit -m "feat: update DeliveryManager with per-duration categories and flash restore callback"
```

---

### Task 5: Update AppDelegate — green dot, observation, flash restore, snooze wiring

**Files:**
- Modify: `Ripple/AppDelegate.swift`

- [ ] **Step 1: Replace the entire AppDelegate.swift**

Replace the contents of `Ripple/AppDelegate.swift` with:

```swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var store = ReminderStore()
    var engine: SchedulerEngine!
    var delivery: DeliveryManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenubarIcon()
        setupScheduler()
        setupPopover()
        updateMenubarIcon()
        observeStoreChanges()
    }

    private func setupMenubarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Ripple")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environment(store)
                .environment(\.schedulerEngine, engine)
        )
    }

    private func setupScheduler() {
        delivery = DeliveryManager(
            statusButton: statusItem.button,
            onSnooze: { [weak self] id, duration in
                self?.engine.snooze(id, duration: duration)
            },
            onNotificationsBlocked: { [weak self] in
                DispatchQueue.main.async { self?.store.notificationsBlocked = true }
            },
            onFlashComplete: { [weak self] in
                self?.updateMenubarIcon()
            }
        )
        delivery.requestAuthorization()
        engine = SchedulerEngine(store: store, delivery: delivery)
        engine.start()
    }

    func updateMenubarIcon() {
        let hasActive = store.reminders.contains { $0.isEnabled }
        let symbolName = hasActive ? "bell.badge.fill" : "bell.fill"
        statusItem.button?.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: "Ripple"
        )
    }

    private func observeStoreChanges() {
        withObservationTracking {
            _ = store.reminders
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.updateMenubarIcon()
                self?.observeStoreChanges()
            }
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button, popover != nil else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
```

- [ ] **Step 2: Build and run all tests**

Press **⌘U**.
Expected: All tests pass, no compiler errors.

- [ ] **Step 3: Commit**

```bash
git add Ripple/AppDelegate.swift
git commit -m "feat: add green dot icon, observation tracking, and flash restore to AppDelegate"
```

---

### Task 6: Add snooze formatting helper

**Files:**
- Modify: `Ripple/Extensions/Reminder+Formatting.swift`

- [ ] **Step 1: Add `snoozeLabel` property**

In `Ripple/Extensions/Reminder+Formatting.swift`, add this computed property inside the `extension Reminder` block, after `activeDaysLabel`:

```swift
    /// "Snooze 5 min" or "Snooze off"
    var snoozeLabel: String {
        guard let mins = snoozeDurationMinutes else { return "Snooze off" }
        return "Snooze \(mins) min"
    }
```

- [ ] **Step 2: Build to confirm it compiles**

Press **⌘B**.
Expected: "Build Succeeded".

- [ ] **Step 3: Commit**

```bash
git add Ripple/Extensions/Reminder+Formatting.swift
git commit -m "feat: add snoozeLabel formatting helper"
```

---

### Task 7: Update ReminderFormView — snooze picker and overnight validation

**Files:**
- Modify: `Ripple/Views/ReminderFormView.swift`

- [ ] **Step 1: Replace `snoozeEnabled` state with `snoozeDurationMinutes`**

In `Ripple/Views/ReminderFormView.swift`, replace the `@State private var snoozeEnabled: Bool` declaration (line 21) with:

```swift
    @State private var snoozeDurationMinutes: Int?
```

- [ ] **Step 2: Update the init to use `snoozeDurationMinutes`**

Replace the `_snoozeEnabled` line in the `init` (line 51) with:

```swift
        _snoozeDurationMinutes = State(initialValue: reminder?.snoozeDurationMinutes)
```

- [ ] **Step 3: Add snooze presets and filtered list**

Add these two properties after the existing `intervalPresets` line (after line 23):

```swift
    private let snoozePresets = [1, 5, 10, 15, 30]

    private var availableSnoozePresets: [Int] {
        guard type == .recurring, let interval = resolvedInterval else { return snoozePresets }
        return snoozePresets.filter { $0 < interval }
    }
```

- [ ] **Step 4: Replace the snooze section**

Replace the entire `snoozeSection` computed property:

```swift
    // MARK: - Snooze

    private var snoozeSection: some View {
        HStack {
            Text("Snooze")
                .font(.subheadline)
                .fontWeight(.medium)

            Picker("Snooze", selection: $snoozeDurationMinutes) {
                Text("Off").tag(Int?.none)
                ForEach(availableSnoozePresets, id: \.self) { mins in
                    Text("\(mins) min").tag(Int?.some(mins))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .onChange(of: resolvedInterval) { _, newInterval in
            if let snooze = snoozeDurationMinutes,
               let interval = newInterval,
               snooze >= interval {
                snoozeDurationMinutes = nil
            }
        }
    }
```

- [ ] **Step 5: Update form validation — remove `start >= end` check**

In the `isValid` computed property, replace:

```swift
            if activeHoursEnabled && activeHoursStart >= activeHoursEnd { return false }
```

with:

```swift
            if activeHoursEnabled && activeHoursStart == activeHoursEnd { return false }
```

- [ ] **Step 6: Update the `save()` function**

In the `save()` function, replace `snoozeEnabled: snoozeEnabled` with `snoozeDurationMinutes: snoozeDurationMinutes`:

```swift
        let reminder = Reminder(
            id: reminderToEdit?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            type: type,
            intervalMinutes: type == .recurring ? resolvedInterval : nil,
            scheduledDate: type == .oneTime ? scheduledDate : nil,
            activeHoursStart: (type == .recurring && activeHoursEnabled) ? activeHoursStart : nil,
            activeHoursEnd: (type == .recurring && activeHoursEnabled) ? activeHoursEnd : nil,
            activeDays: type == .recurring ? finalDays : nil,
            isEnabled: reminderToEdit?.isEnabled ?? true,
            delivery: DeliveryOptions(
                notification: notificationEnabled,
                sound: soundEnabled,
                menubarIconFlash: menubarFlashEnabled
            ),
            snoozeDurationMinutes: snoozeDurationMinutes
        )
```

- [ ] **Step 7: Build to confirm it compiles**

Press **⌘B**.
Expected: "Build Succeeded".

- [ ] **Step 8: Commit**

```bash
git add Ripple/Views/ReminderFormView.swift
git commit -m "feat: replace snooze toggle with duration picker, allow overnight hour ranges"
```

---

### Task 8: Update ReminderDetailView — show snooze duration

**Files:**
- Modify: `Ripple/Views/ReminderDetailView.swift`

- [ ] **Step 1: Add snooze info to the detail view**

In `Ripple/Views/ReminderDetailView.swift`, add a snooze row after the delivery tags section. Insert this between the `}` closing the `HStack(spacing: 8)` block and the `Spacer()`:

```swift
            // Snooze
            Text("SNOOZE")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(reminder.snoozeLabel)
                .font(.subheadline)
```

- [ ] **Step 2: Build to confirm it compiles**

Press **⌘B**.
Expected: "Build Succeeded".

- [ ] **Step 3: Commit**

```bash
git add Ripple/Views/ReminderDetailView.swift
git commit -m "feat: show snooze duration in reminder detail view"
```

---

### Task 9: Build, run all tests, and verify

- [ ] **Step 1: Run all tests**

Press **⌘U**.
Expected: All tests pass — existing tests plus new snooze and overnight tests.

- [ ] **Step 2: Run the app and verify green dot**

Press **⌘R**. Click the bell icon:
- If you have active reminders (or add one), the icon should show `bell.badge.fill` (bell with dot)
- Disable all reminders via toggles → icon should change to `bell.fill` (plain bell)
- Re-enable a reminder → dot returns

- [ ] **Step 3: Verify snooze picker**

Click "+ Add". Set type to Recurring, interval to 15 min:
- The snooze picker should show: Off, 1 min, 5 min, 10 min (no 15 or 30 since they're >= interval)
- Change interval to 30 min → snooze picker should now include 15 min

Click "+ Add". Set type to One-time:
- The snooze picker should show all presets: Off, 1 min, 5 min, 10 min, 15 min, 30 min

- [ ] **Step 4: Verify overnight active hours**

Click "+ Add". Set type to Recurring, enable Active hours:
- Set start to 10:00 PM, end to 6:00 AM
- The "Add Reminder" button should be enabled (this was previously blocked by validation)

- [ ] **Step 5: Stop the app**

Press **⌘.** in Xcode.

---

### Task 10: Update README and commit docs

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update the Scheduling section**

In `README.md`, replace the snooze line:

```
- **Snooze**: reschedules +5 min from dismissal
```

with:

```
- **Snooze**: configurable per-reminder duration (1, 5, 10, 15, or 30 min); must be shorter than the reminder's interval
```

- [ ] **Step 2: Update the UI table**

Replace the Menubar icon row:

```
| Menubar icon | Filled bell (`bell.fill` SF Symbol); flashes on trigger |
```

with:

```
| Menubar icon | Bell with dot (`bell.badge.fill`) when any reminder is active; plain bell otherwise; flashes on trigger |
```

Replace the System notification row:

```
| System notification | Title with optional "Snooze" action button (if snooze enabled) |
```

with:

```
| System notification | Title with optional "Snooze N min" action button (if snooze duration set) |
```

- [ ] **Step 3: Update the Scheduling section — active hours**

After the "Recurring" bullet, add:

```
- **Active hours**: supports both daytime (9am–5pm) and overnight (10pm–6am) ranges; overnight windows check the previous day for active-day filtering
```

- [ ] **Step 4: Update the Not Yet Implemented section**

Remove these three lines (they are now implemented):

```
- Green dot on menubar icon when any reminder is active
- Configurable snooze duration (currently fixed at 5 minutes)
- Overnight active hour ranges (e.g. 10pm–6am)
```

- [ ] **Step 5: Commit**

```bash
git add README.md CHANGELOG.md
git commit -m "docs: update README and CHANGELOG for green dot, snooze, and overnight hours"
```
