# Ripple — Step 3: Scheduling Engine Design
**Date:** 2026-03-28
**Scope:** In-process tick-based scheduler that fires reminders and delivers via system notification, sound, and menubar flash.

---

## Constraints

- Reminders fire **only while the app is running** — no background launch or persistent system scheduling
- Tick resolution is **60 seconds** — reminders fire on the next tick after their condition is met
- All scheduling state (last fire times, snooze expiry) is **in-memory only** — not persisted across restarts

---

## Architecture

Two new files in a `Ripple/Scheduling/` group, one new test file:

```
Ripple/Scheduling/
  SchedulerEngine.swift    — tick timer, fire logic, snooze tracking
  DeliveryManager.swift    — notification, sound, menubar flash
RippleTests/
  SchedulerEngineTests.swift
```

`AppDelegate` owns both objects and wires them at launch. `SchedulerEngine` reads from `ReminderStore` and calls `DeliveryManager` when a reminder fires. `DeliveryManager` holds a weak reference to the `NSStatusItem` button for menubar flash.

```
AppDelegate
 ├── ReminderStore       (existing)
 ├── SchedulerEngine     (new) ← reads store, calls DeliveryManager
 └── DeliveryManager     (new) ← weak ref to NSStatusItem.button for flash
```

---

## SchedulerEngine

A `final class` that owns a `Timer` firing every 60 seconds.

### Fire Conditions

**Recurring reminders** (`.type == .recurring`) fire when ALL are true:
- `isEnabled == true`
- Current weekday is in `activeDays`, or `activeDays == nil` (all days)
- Current time (minutes since midnight) is within `activeHoursStart...activeHoursEnd`, or either bound is nil (all hours)
- At least `intervalMinutes` have elapsed since last fire
- Not currently snoozed

**One-time reminders** (`.type == .oneTime`) fire when:
- `isEnabled == true`
- Current time ≥ `scheduledDate`
- After firing, engine calls `store.update(reminder)` with `isEnabled = false`

### State

```swift
private var lastFired: [UUID: Date] = [:]     // tracks last fire time per reminder
private var snoozedUntil: [UUID: Date] = [:]  // tracks snooze expiry per reminder
```

Both dictionaries are in-memory only. Entries in `snoozedUntil` whose expiry has passed are removed on the next tick.

### Snooze

When the user taps "Snooze" on a notification, `DeliveryManager` receives the `UNNotificationResponse` and calls a `onSnooze: (UUID) -> Void` closure provided by `SchedulerEngine` at init. The engine sets `snoozedUntil[id] = now() + 5 * 60`.

### Testability

`SchedulerEngine` takes a `now: () -> Date` closure (defaults to `Date.init`) so tests can inject a fixed time without real timers. The tick logic is extracted into an internal `func checkAndFire()` method that tests call directly.

### Public API

```swift
final class SchedulerEngine {
    init(store: ReminderStore, delivery: DeliveryManagerProtocol, now: @escaping () -> Date = Date.init)
    func start()            // starts the 60-second Timer
    func stop()             // invalidates the Timer
    func snooze(_ id: UUID) // called by DeliveryManager via onSnooze callback
}
```

> **Active hours assumption:** `activeHoursStart` must be ≤ `activeHoursEnd` (same calendar day). Overnight ranges (e.g. 22:00–06:00) are not supported in this step.

---

## DeliveryManager

A `final class` responsible for all three delivery channels. Called by `SchedulerEngine` via the `DeliveryManagerProtocol`.

### Protocol

```swift
protocol DeliveryManagerProtocol {
    func deliver(_ reminder: Reminder)
}
```

### Notification (`delivery.notification == true`)

- Requests `UNUserNotificationCenter` authorization (`.alert`, `.sound`) on `AppDelegate.applicationDidFinishLaunching`, before the engine starts
- Registers a `UNNotificationCategory` with identifier `"REMINDER"` containing a single `UNNotificationAction` with identifier `"SNOOZE"` and title `"Snooze"` (only attached to requests where `reminder.snoozeEnabled == true`)
- Before sending, checks `UNUserNotificationCenter.getNotificationSettings()`. If `authorizationStatus == .denied`, calls `onNotificationsBlocked()` instead of sending
- Fires a `UNNotificationRequest` with:
  - `identifier`: reminder's UUID string (deduplicates concurrent delivery)
  - `title`: reminder's `title`
  - `categoryIdentifier`: `"REMINDER"` if snooze enabled, else omitted
- Implements `UNUserNotificationCenterDelegate` to receive the snooze action response and invoke the `onSnooze` callback
- Also implements `willPresent` delegate to show banners and play sounds when the app is in the foreground

### Sound (`delivery.sound == true`)

Plays `NSSound(named: .init("Glass"))`. No extra assets required.

### Menubar Flash (`delivery.menubarIconFlash == true`)

Holds a `weak var statusButton: NSStatusBarButton?`. Alternates the button image between `bell.fill` and `bell` four times over two seconds using a short-lived `Timer`, then restores `bell.fill`.

### Wiring in AppDelegate

```swift
delivery = DeliveryManager(
    statusButton: statusItem.button,
    onSnooze: { [weak self] id in self?.engine.snooze(id) },
    onNotificationsBlocked: { [weak self] in
        DispatchQueue.main.async { self?.store.notificationsBlocked = true }
    }
)
```

`AppDelegate` calls `delivery.requestAuthorization()` once after creating the `DeliveryManager`, before starting the engine.

---

## Tests

All tests in `SchedulerEngineTests.swift` use an injected `now` closure and a real `ReminderStore` backed by a temp file URL. `DeliveryManager` is replaced by a `SpyDelivery: DeliveryManagerProtocol` that records calls.

| Test | Verifies |
|------|----------|
| `test_recurring_firesWhenDue` | fires after `intervalMinutes` elapsed |
| `test_recurring_doesNotFireBeforeInterval` | does not fire if interval hasn't elapsed |
| `test_recurring_respectsActiveHours` | skips when current time is outside active hours |
| `test_recurring_respectsActiveDays` | skips when current weekday not in `activeDays` |
| `test_recurring_allDaysWhenActiveDaysNil` | fires on any day when `activeDays == nil` |
| `test_recurring_skipsWhenSnoozed` | skips reminder within snooze window |
| `test_recurring_firesAfterSnoozeExpires` | fires again once snooze window passes |
| `test_oneTime_firesAndDisables` | fires once and sets `isEnabled = false` |
| `test_disabled_neverFires` | skips `isEnabled == false` reminders |

`DeliveryManager` itself is not unit tested — it wraps system APIs (`UNUserNotificationCenter`, `NSSound`, `NSStatusBarButton`) that require a running app environment.

---

## What This Does Not Cover

- Firing reminders when the app is not running
- Configurable snooze duration (fixed at 5 minutes)
- Snooze via in-app UI (deferred to Step 4 UI)
- Sound selection (fixed to system Glass sound)
- Full SwiftUI reminder list UI (Step 4)
