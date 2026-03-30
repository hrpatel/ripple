# Ripple

A lightweight macOS menubar app for setting and triggering one-time or recurring reminders. Small, consistent actions ripple outward into long-term wellbeing.

**Primary use cases:** sit/stand desk reminders, break reminders, hydration reminders, and general time-based nudges.

## Architecture

- Lives entirely in the **menubar** (no dock icon, no separate window)
- Built with **Swift + SwiftUI**
- `NSStatusItem` for menubar presence
- `UserNotifications` for system notifications
- `AVFoundation` for sound/chime playback
- Local persistence via JSON in Application Support

## Data Model

| Type | Purpose |
|------|---------|
| `Reminder` | Core model — title, type (recurring/one-time), interval, schedule, active hours/days, delivery options, snooze |
| `DeliveryOptions` | Notification, sound, and menubar icon flash toggles |
| `ReminderType` | `.recurring` or `.oneTime` |
| `Weekday` | Mon–Sun for active-day selection |

## Scheduling

- On launch and after any save, all upcoming trigger times are recalculated
- **Recurring**: fires every *N* minutes within active hours, on active days only
- **One-time**: fires once at the scheduled date/time, then auto-disables
- **Delivery**: notification, sound, and/or menubar flash based on per-reminder settings
- **Snooze**: reschedules +5 min from dismissal

## UI

| Screen | Description |
|--------|-------------|
| Menubar icon | Bell with green dot when any reminder is active |
| Dropdown panel | Reminder list with Active / All / Paused tabs and "+ Add" button |
| Detail view | Title, interval, active hours/days, next trigger, delivery method tags |
| Add/Edit form | Full reminder configuration — type, interval, hours, days, delivery, snooze |
| System notification | Title, contextual body, optional "Snooze 5 min" action |

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
