# Ripple — Project Brief

## Overview
A lightweight macOS menubar app for setting and triggering one-time or recurring reminders. The philosophy: small, consistent actions ripple outward into long-term wellbeing. Primary use cases: sit/stand desk reminders, break reminders, hydration reminders, and general time-based nudges.

---

## App architecture
- Lives entirely in the **menubar** (no dock icon, no separate window)
- Built with **Swift + SwiftUI**
- Uses `NSStatusItem` for the menubar presence
- Uses `UserNotifications` framework for system notifications
- Uses `AVFoundation` for sound/chime playback
- Reminder state persisted locally (e.g. via `UserDefaults` or a JSON file in Application Support)

---

## Data model

```swift
struct Reminder: Identifiable, Codable {
    var id: UUID
    var title: String
    var type: ReminderType         // .recurring | .oneTime
    var intervalMinutes: Int?      // recurring only
    var scheduledDate: Date?       // one-time only
    var activeHoursStart: Date?    // recurring only (time component only)
    var activeHoursEnd: Date?      // recurring only
    var activeDays: Set<Weekday>   // recurring only
    var isEnabled: Bool
    var delivery: DeliveryOptions
    var snoozeEnabled: Bool
}

enum ReminderType: String, Codable { case recurring, oneTime }

struct DeliveryOptions: Codable {
    var notification: Bool
    var sound: Bool
    var menubarIconFlash: Bool
}

enum Weekday: Int, Codable, CaseIterable {
    case mon=1, tue, wed, thu, fri, sat, sun
}
```

---

## UI screens

### 1. Menubar icon
- Bell icon with a green dot when any reminder is active
- Clicking opens the dropdown panel

### 2. Dropdown panel (main view)
- Header: "Reminders" title + "+ Add" button
- Tab bar: Active / All / Paused
- Reminder list rows: toggle switch, title, subtitle (interval + hours), recurring/one-time badge
- Clicking a row opens the detail view

### 3. Reminder detail view
- Shows: title, interval, active hours, active days, next trigger time
- Delivery method tags (Notification, Sound, Menubar icon) — highlighted if on
- "Edit reminder" button

### 4. Add / Edit reminder form
- Fields:
  - Title (text input)
  - Type (Recurring / One-time selector)
  - If recurring: Interval (15/30/45/60/90 min, 2hr, custom), Active hours (time range), Active days (M T W T F S S pill toggles)
  - If one-time: Date & time picker
  - Delivery toggles: Notification, Sound / chime, Menubar icon flash
  - Snooze toggle (dismiss for 5 min from notification)
- Footer: Delete (edit only) | Cancel | Save / Add reminder

### 5. System notification
- App name: "Reminders"
- Title: reminder title (e.g. "Time to stand up")
- Body: contextual message (e.g. "You've been sitting for 45 minutes.")
- Action button: "Snooze 5 min" (if snooze enabled)

---

## Scheduling logic
- On launch and after any save, recalculate all upcoming trigger times
- For recurring reminders: fire every N minutes within the active hours window, on active days only
- For one-time reminders: fire once at the scheduled date/time, then auto-disable
- On trigger: deliver via whichever delivery methods are enabled (notification, sound, menubar flash)
- Snooze: reschedule the reminder +5 min from dismissal time

---

## Suggested build order
1. App shell — `NSStatusItem` menubar agent, no dock icon (`LSUIElement = YES` in Info.plist)
2. Data model + persistence layer
3. Scheduling engine (recurring + one-time, respects active hours/days)
4. Notification delivery (`UNUserNotificationCenter`)
5. Sound playback (`AVAudioPlayer` with a bundled chime)
6. Menubar icon flash on trigger
7. SwiftUI dropdown panel (list + detail view)
8. Add/Edit form
9. Snooze handling from notification action
10. Polish: launch at login toggle, onboarding for notification permissions
