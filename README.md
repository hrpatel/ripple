# Ripple

A lightweight macOS menubar app for setting and triggering one-time or recurring reminders. Small, consistent actions ripple outward into long-term wellbeing.

**Primary use cases:** sit/stand desk reminders, break reminders, hydration reminders, and general time-based nudges.

## Architecture

- Lives entirely in the **menubar** (no dock icon, no separate window)
- Built with **Swift + SwiftUI**
- `NSStatusItem` + `NSPopover` for menubar presence and popover panel
- `UserNotifications` for system notifications
- `NSSound` for system sound playback
- `ServiceManagement` (`SMAppService`) for launch-at-login
- Local persistence via JSON in Application Support

## Data Model

| Type | Purpose |
|------|---------|
| `Reminder` | Core model — title, type (recurring/one-time), interval, schedule, active hours/days, delivery options, snooze |
| `DeliveryOptions` | Notification, sound, and menubar icon flash toggles |
| `ReminderType` | `.recurring` or `.oneTime` |
| `Weekday` | Mon–Sun for active-day selection |

## Scheduling

- `SchedulerEngine` polls every **60 seconds** via a repeating `Timer`
- Reminders only fire **while the app is running** — no background launch or persistent system scheduling
- Scheduling state (last fire times, snooze expiry) is **in-memory only** — resets on restart
- **Recurring**: fires every *N* minutes within active hours, on active days only
- **One-time**: fires once at the scheduled date/time, then auto-disables
- **Delivery**: notification, sound (system "Glass"), and/or menubar icon flash based on per-reminder settings
- **Snooze**: configurable per-reminder duration (1, 5, 10, 15, or 30 min); must be shorter than the reminder's interval
- **Active hours**: supports both daytime (9am–5pm) and overnight (10pm–6am) ranges; overnight windows check the previous day for active-day filtering
- **Permission check**: if notifications are denied, sets a `notificationsBlocked` flag and shows a banner

## UI

| Screen | Description |
|--------|-------------|
| Menubar icon | Bell with dot (`bell.badge.fill`) when any reminder is active; plain bell otherwise; flashes on trigger |
| Popover panel | Reminder list with All / Active / Paused tabs, "+ Add" button, and launch-at-login toggle |
| Notification banner | Yellow warning when system notifications are blocked, with link to System Settings |
| Detail view | Title, interval, active hours/days, next trigger, delivery method tags |
| Add/Edit form | Full reminder configuration — type, interval, hours, days, delivery, snooze |
| System notification | Title with optional "Snooze N min" action button (if snooze duration set) |

## Not Yet Implemented

- Notification body text (e.g. "You've been sitting for 45 minutes")
- Configurable sound selection (currently hardcoded to system "Glass" sound)

## Project Structure

```
Ripple/
├── RippleApp.swift              # App entry point
├── AppDelegate.swift            # NSStatusItem setup, menubar agent
├── ContentView.swift            # Root NavigationStack and routing
├── Extensions/
│   └── Reminder+Formatting.swift # Display helpers (subtitle, interval, hours, days labels)
├── Models/
│   └── Reminder.swift           # Reminder, DeliveryOptions, Weekday, ReminderType
├── Scheduling/
│   ├── DeliveryManager.swift    # Notifications, sound playback, menubar flash
│   └── SchedulerEngine.swift    # Timer-based recurring/one-time firing logic
├── Store/
│   ├── ReminderStore.swift      # In-memory reminder state management
│   └── PersistenceManager.swift # JSON file read/write in Application Support
└── Views/
    ├── ReminderListView.swift   # Active / All / Paused tabs with reminder rows
    ├── ReminderRowView.swift    # Single reminder row in the list
    ├── ReminderDetailView.swift # Read-only reminder detail with next-fire info
    └── ReminderFormView.swift   # Add/edit form for reminder configuration
```
