# Step 10: Polish — Design Spec

> Phase 2, Step 10 of the Ripple implementation plan.

## Goal

Add three polish features to complete the app: launch at login, app icon, and a notification permission warning shown when delivery silently fails.

---

## Feature 1: Launch at Login

### Mechanism

Use `SMAppService.mainApp` (macOS 13+) to register and unregister the app as a login item.

### UI

A toggle row sits below the reminder list in `ReminderListView`, outside the `List` component:

```
[toggle] Launch at login
```

- On view appear, read `SMAppService.mainApp.status` to set the initial toggle state
- Toggle on → `try? SMAppService.mainApp.register()`
- Toggle off → `try? SMAppService.mainApp.unregister()`
- Errors from register/unregister are swallowed silently (this is a best-effort preference)

### Constraints

- Requires `import ServiceManagement`
- `SMAppService` requires macOS 13+; the project already targets macOS 14+, so no version guard needed

---

## Feature 2: App Icon

### Mechanism

No code changes. The user provides a 1024×1024 PNG and the implementation plan walks through the Xcode steps to add it to `Assets.xcassets` as the `AppIcon` image set.

### Constraints

- Menubar icon remains `bell.fill` SF Symbol (unchanged)
- App icon appears in Finder, the Dock (if ever shown), and macOS app switcher

---

## Feature 3: Notification Permission Warning

### Trigger

When `DeliveryManager.deliver()` is called for a reminder with `delivery.notification = true`, check notification authorization status before sending. If `.denied`, skip the notification and set `store.notificationsBlocked = true`.

### ReminderStore change

Add one new observable property:

```swift
var notificationsBlocked = false
```

### DeliveryManager change

Add an `onNotificationsBlocked: @escaping () -> Void` callback to `DeliveryManager.init` (consistent with the existing `onSnooze` pattern). `AppDelegate` wires it: `{ [weak self] in DispatchQueue.main.async { self?.store.notificationsBlocked = true } }`.

In `deliver()`, when `reminder.delivery.notification == true`, call `UNUserNotificationCenter.current().getNotificationSettings()` before sending. In the completion handler: if `authorizationStatus == .denied`, call `onNotificationsBlocked()` and return; otherwise proceed with `sendNotification(for:)`. The existing `requestAuthorization()` call at launch is unchanged.

### UI

`ReminderListView` shows a yellow banner at the very top of the view when `store.notificationsBlocked == true`:

```
⚠ Notifications are blocked — reminders won't appear.   [Open System Settings]
```

- "Open System Settings" opens `x-apple.systempreferences:com.apple.preference.notifications` via `NSWorkspace.shared.open(_:)`
- The banner is not dismissible — it disappears automatically if/when the user grants permission (on next delivery attempt the flag would not be set again... but since the flag is not reset automatically, the simplest approach is: the banner persists until the app is relaunched after permissions are fixed)
- `notificationsBlocked` starts as `false` and is never persisted — it resets on relaunch

### Constraints

- No new tests — `DeliveryManager` has no existing tests; this change doesn't introduce a new test gap beyond what already exists
- The permission check is async; the notification send must happen in the completion handler on the main thread

---

## Files Changed

| Action | File | Change |
|--------|------|--------|
| Modify | `Ripple/Store/ReminderStore.swift` | Add `var notificationsBlocked = false` |
| Modify | `Ripple/Scheduling/DeliveryManager.swift` | Add `onNotificationsBlocked` callback; check auth status before sending notification; invoke callback if denied |
| Modify | `Ripple/AppDelegate.swift` | Wire `onNotificationsBlocked` callback to set `store.notificationsBlocked = true` on main |
| Modify | `Ripple/Views/ReminderListView.swift` | Launch-at-login toggle below list; notification blocked banner above list |
| Asset | `Ripple/Assets.xcassets/AppIcon.appiconset` | User-provided 1024×1024 PNG (Xcode GUI steps) |

---

## Out of Scope

- Notification permission onboarding at first launch
- Resetting `notificationsBlocked` automatically when permissions are re-granted
- Any other settings (snooze duration, custom sounds, etc.)
- The user's queued UX changes (separate step)
