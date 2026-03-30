# Green Dot, Configurable Snooze, Overnight Hours — Design Spec

> Phase 2 polish features for the Ripple app.

## Goal

Three independent improvements: a green dot on the menubar icon when reminders are active, configurable per-reminder snooze duration, and support for overnight active hour ranges.

---

## Feature 1: Green Dot on Menubar Icon

### Behavior

The menubar icon reflects whether any reminder is currently active:
- **At least one** `isEnabled == true` reminder exists → `bell.badge.fill` (bell with dot)
- **Zero** enabled reminders → `bell.fill` (plain bell)

The icon updates whenever a reminder is added, updated, deleted, or toggled.

### Mechanism

`AppDelegate` owns the `NSStatusItem` and already has access to `store`. Add a method `updateMenubarIcon()` that reads `store.reminders.contains { $0.isEnabled }` and sets the button image accordingly.

Call `updateMenubarIcon()`:
- In `applicationDidFinishLaunching`, after `setupScheduler()`
- After every `store` mutation — use `withObservationTracking` on `store.reminders` to detect changes and re-evaluate

### SF Symbols

- Active: `bell.badge.fill` — provides a native dot indicator
- Inactive: `bell.fill` — current icon

### Constraints

- No custom drawing — SF Symbols only
- The flash animation in `DeliveryManager` continues to alternate `bell.fill` / `bell` during a flash. After the flash completes, it should call back to `AppDelegate` to restore the correct icon (badge or plain) rather than hardcoding `bell.fill`.

---

## Feature 2: Configurable Snooze Duration

### Model Change

Replace `snoozeEnabled: Bool` with `snoozeDurationMinutes: Int?` on `Reminder`:
- `nil` → snooze is off
- A value (e.g. `5`) → snooze is on with that duration

This is a breaking change to the persisted JSON format. Existing reminders will fail to decode and be replaced with an empty array on first launch. Acceptable for a personal-use app.

### Presets

Available durations: **1, 5, 10, 15, 30** minutes.

### Interval Constraint

The snooze duration must be shorter than the reminder's `intervalMinutes` for recurring reminders. Otherwise the snooze would outlast the next regular fire.

- **Form UI:** Filter the preset list to only show values strictly less than `intervalMinutes`. For one-time reminders, show all presets (no interval to conflict with).
- **Interval change:** If the user changes the interval to something shorter than the current snooze duration, clear `snoozeDurationMinutes` to `nil` (snooze off). The user can re-pick.

### Form UI

Replace the current snooze toggle (`Toggle("Snooze (5 min)")`) with a picker:
- Label: "Snooze"
- Options: "Off", "1 min", "5 min", "10 min", "15 min", "30 min" (filtered by interval)
- Default: "Off"
- Style: `.menu` picker (same as the interval picker)

### SchedulerEngine

Change `snooze(_ id: UUID)` to `snooze(_ id: UUID, duration: Int)`. The caller passes the reminder's `snoozeDurationMinutes`. The engine sets `snoozedUntil[id] = now() + duration * 60`.

### DeliveryManager

- The notification action title changes to reflect the duration: "Snooze 5 min", "Snooze 10 min", etc.
- Since each reminder may have a different snooze duration, register a `UNNotificationCategory` per unique duration (e.g. `"REMINDER_5"`, `"REMINDER_10"`), each with its own `UNNotificationAction` title.
- Set the request's `categoryIdentifier` to the matching category.
- When the snooze action is received, look up the reminder from the store by ID to get its `snoozeDurationMinutes`, and pass it to `engine.snooze(id, duration:)`.

### Constraints

- `snoozeDurationMinutes` is `nil` when snooze is off — not `0`
- One-time reminders can use any snooze preset (no interval constraint)
- The `onSnooze` callback signature changes from `(UUID) -> Void` to `(UUID, Int) -> Void` to pass the duration

---

## Feature 3: Overnight Active Hours

### Behavior

Active hours currently require `start <= end` (same-day range like 9am–5pm). This adds support for overnight ranges where `start > end` (e.g. 10pm–6am).

An overnight range like 10pm–6am means the reminder fires from 10:00 PM to 11:59 PM, and from 12:00 AM to 6:00 AM.

### SchedulerEngine Change

Replace the active hours check in `shouldFireRecurring`:

```
Current:
    guard mins >= start && mins <= end

New:
    if start <= end {
        // Daytime: e.g. 9am–5pm
        guard mins >= start && mins <= end
    } else {
        // Overnight: e.g. 10pm–6am
        guard mins >= start || mins <= end
    }
```

### Active Days for Overnight Windows

When `start > end` (overnight) and the current time is in the "after midnight" portion (`mins <= end`), the window started on the previous calendar day. The active days check must use the **previous day's weekday**, not today's.

Example: Active hours 10pm–6am, active days Mon–Fri.
- Friday 11pm → check Friday → active ✓
- Saturday 2am → this is the Friday night window → check Friday → active ✓
- Saturday 11pm → check Saturday → not active ✗

Implementation: if `start > end && mins <= end`, subtract 1 from the calendar weekday (wrapping Sunday → Saturday) before checking `activeDays`.

### Form Validation Change

Remove the `activeHoursStart >= activeHoursEnd` validation in `ReminderFormView.isValid`. The only invalid state is `start == end` (zero-length window), which should be disallowed.

### Formatting

`Reminder+Formatting.swift`'s `activeHoursLabel` already formats any two `Int` values as times. An overnight range like 1320–360 displays as "10pm – 6am" with no changes needed.

### Constraints

- No model changes — `activeHoursStart` and `activeHoursEnd` are already `Int?`
- Overnight ranges do not span more than 24 hours (start and end are both 0–1439)
- The `nextFireDate(for:)` method does not account for active hours (documented limitation) — no change needed

---

## Files Changed

| Action | File | Change |
|--------|------|--------|
| Modify | `Ripple/Models/Reminder.swift` | Replace `snoozeEnabled: Bool` with `snoozeDurationMinutes: Int?` |
| Modify | `Ripple/AppDelegate.swift` | Add `updateMenubarIcon()`, observation tracking, flash restore callback |
| Modify | `Ripple/Scheduling/SchedulerEngine.swift` | Overnight hours logic, `snooze(_:duration:)` |
| Modify | `Ripple/Scheduling/DeliveryManager.swift` | Per-duration notification categories, `onSnooze` signature change, flash restore callback |
| Modify | `Ripple/Views/ReminderFormView.swift` | Snooze picker (filtered by interval), remove `start >= end` validation |
| Modify | `Ripple/Views/ReminderDetailView.swift` | Display snooze duration instead of on/off |
| Modify | `Ripple/Extensions/Reminder+Formatting.swift` | Add snooze label helper |
| Modify | `RippleTests/SchedulerEngineTests.swift` | Overnight hours tests, snooze duration tests |
| Modify | `RippleTests/ReminderStoreTests.swift` | Update `makeReminder` helper for new model field |
| Modify | `RippleTests/PersistenceManagerTests.swift` | Update test reminders for new model field |
| Modify | `README.md` | Move implemented features out of "Not Yet Implemented", update Scheduling and UI sections |
| Modify | `CHANGELOG.md` | Record changes for this release |

---

## Out of Scope

- Custom snooze duration (free-text entry)
- App-wide snooze default setting
- `nextFireDate` accounting for active hours
- Resetting `notificationsBlocked` automatically
- Notification body text
