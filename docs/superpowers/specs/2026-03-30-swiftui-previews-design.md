# SwiftUI Previews for Ripple Views

**Date:** 2026-03-30
**Status:** Approved

## Goal

Add `#Preview` blocks to all 5 SwiftUI views in the Ripple project, simulating the menu bar popover dimensions and covering multiple states per view.

## Decisions

- **Popover simulation:** All previews constrained to `.frame(width: 320)` to match the real popover width.
- **Shared sample data:** A `Reminder` extension with static sample instances, reused across all previews.
- **SchedulerEngine abstraction:** Extract a `SchedulerEngineProtocol` so previews use a lightweight stub instead of the real timer-based engine.
- **Multiple named previews:** Each view gets several previews covering its key states (happy path, empty, paused, etc.).
- **DEBUG-only:** Sample data and preview stub are wrapped in `#if DEBUG`.

## New Files

### `Ripple/Models/Reminder+SampleData.swift`

`#if DEBUG` extension providing:

- `Reminder.sampleRecurring` — "Stretch break", every 45 min, 9am–5pm Mon–Fri, notification + sound, snooze 5 min, enabled
- `Reminder.sampleOneTime` — "Team standup", scheduled 1 hour from now, notification only, enabled
- `Reminder.samplePaused` — "Drink water", every 30 min, all day every day, disabled
- `Reminder.samples` — array of all three
- `PreviewSchedulerEngine` — conforms to `SchedulerEngineProtocol`, returns `Date().addingTimeInterval(900)` for enabled reminders, `nil` for disabled

## Modified Files

### `Ripple/Scheduling/SchedulerEngine.swift`

- Add `SchedulerEngineProtocol` with `func nextFireDate(for: Reminder) -> Date?`
- `SchedulerEngine` conforms to it (method already exists)

### `Ripple/ContentView.swift`

- Change `SchedulerEngineKey.defaultValue` type from `SchedulerEngine?` to `(any SchedulerEngineProtocol)?`
- Change `EnvironmentValues.schedulerEngine` property type to match
- Add one `#Preview` block: "Default" with sample store + `PreviewSchedulerEngine`

### `Ripple/Views/ReminderRowView.swift`

Add 3 `#Preview` blocks:
- "Enabled Recurring" — `sampleRecurring`
- "Enabled One-Time" — `sampleOneTime`
- "Paused" — `samplePaused`

### `Ripple/Views/ReminderDetailView.swift`

Add 3 `#Preview` blocks:
- "Recurring Detail" — `sampleRecurring` + `PreviewSchedulerEngine`
- "One-Time Detail" — `sampleOneTime` + `PreviewSchedulerEngine`
- "Paused Detail" — `samplePaused` + `PreviewSchedulerEngine`

### `Ripple/Views/ReminderFormView.swift`

Add 3 `#Preview` blocks:
- "Add New" — no reminder, store with sample data
- "Edit Recurring" — `sampleRecurring`, store with sample data
- "Edit One-Time" — `sampleOneTime`, store with sample data

### `Ripple/Views/ReminderListView.swift`

Add 3 `#Preview` blocks:
- "With Reminders" — store populated with all 3 samples
- "Empty" — store with no reminders
- "Notifications Blocked" — store with samples + `notificationsBlocked = true`

## Preview Store Pattern

All previews create a `ReminderStore` that doesn't touch disk:

```swift
let store = ReminderStore(persistenceURL: URL(fileURLWithPath: "/dev/null"))
store.reminders = [.sampleRecurring, .sampleOneTime, .samplePaused]
```

## Out of Scope

- Snapshot testing or automated preview validation
- Preview for `AppDelegate` or `RippleApp` (AppKit, not SwiftUI views)
