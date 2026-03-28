# Ripple — Implementation Plan

## Prerequisites
- Mac running macOS 13 (Ventura) or later
- Xcode 15+ installed (free from the Mac App Store)
- Basic familiarity with Swift (helpful but not required — Claude can guide each step)
- Git installed (`git --version` in Terminal to check; install via Xcode Command Line Tools if missing)

---

## Phase 1: Project setup

### 1.1 Create the Xcode project
1. Open Xcode → New Project → macOS → App
2. Set the following:
   - Product Name: `Ripple`
   - Interface: SwiftUI
   - Language: Swift
   - Uncheck "Include Tests" for now (add later)
3. Choose a local folder to save the project

### 1.2 Configure as a menubar-only app
1. Open `Info.plist`
2. Add a new key: `Application is agent (UIElement)` → set value to `YES`
   - This hides the app from the Dock and removes the menu bar at the top of the screen
3. In `YourAppApp.swift`, replace the default `WindowGroup` with an `NSStatusItem`-based setup (Claude can generate this code)

### 1.3 Set up Git
```bash
cd /path/to/your/project
git init
git add .
git commit -m "Initial project setup"
```
Optionally, create a repo on GitHub and push:
```bash
git remote add origin https://github.com/yourusername/your-repo.git
git push -u origin main
```

---

## Phase 2: Build the app (in order)

Follow the build order below. Ask Claude to generate the code for each step, then paste it into Xcode, build (⌘B), and verify before moving on.

### Step 1 — App shell
- Set up `NSStatusItem` in the menubar
- Show a placeholder popover when the icon is clicked
- Confirm the app has no Dock icon

### Step 2 — Data model + persistence
- Define `Reminder`, `ReminderType`, `DeliveryOptions`, and `Weekday` structs (see project brief)
- Implement save/load using `UserDefaults` or a JSON file in `~/Library/Application Support/`
- Write a simple `ReminderStore` observable object to hold and manage reminders

### Step 3 — Scheduling engine
- On app launch and after every save, calculate next trigger times for all enabled reminders
- For recurring reminders: fire every N minutes within active hours, on active days only
- For one-time reminders: fire once at the scheduled time, then auto-disable
- Use `DispatchQueue` or `Timer` to poll, or `UNUserNotificationCenter` to schedule directly

### Step 4 — Notification delivery
- Request notification permissions on first launch (`UNUserNotificationCenter.requestAuthorization`)
- Schedule `UNNotificationRequest` for each upcoming trigger
- Handle notification responses (dismiss, snooze)

### Step 5 — Sound playback
- Bundle a short chime audio file (`.aiff` or `.mp3`) in the Xcode project
- Use `AVAudioPlayer` to play it on trigger (only if sound delivery is enabled)

### Step 6 — Menubar icon flash
- On trigger, temporarily swap the `NSStatusItem` image to an "active" variant
- Revert after ~2 seconds

### Step 7 — SwiftUI dropdown panel
- Reminder list with toggle switches, title, subtitle, and recurring/one-time badge
- Tab bar: Active / All / Paused
- Clicking a row shows the detail view (interval, hours, days, next trigger, delivery tags)

### Step 8 — Add / Edit reminder form
- Fields: title, type, interval (recurring) or date+time (one-time), active hours, active days, delivery toggles, snooze toggle
- Type selector dynamically shows/hides relevant fields
- Footer: Delete (edit only) | Cancel | Save

### Step 9 — Snooze handling
- Add a "Snooze 5 min" action to the notification
- On snooze: reschedule a one-off trigger 5 minutes from dismissal time

### Step 10 — Polish
- Launch at login toggle (use `ServiceManagement` framework)
- Request notification permissions gracefully with an explanation prompt
- App icon (1024x1024 PNG, added via Xcode asset catalog)

---

## Phase 3: Testing

### Manual testing (do this after each phase 2 step)
- Run the app in Xcode with ⌘R
- Test the specific feature you just built before moving on

### Unit testing the scheduling engine (Step 3)
1. In Xcode: File → New → Target → Unit Testing Bundle
2. Write `XCTestCase` tests for:
   - Correct next trigger calculation for recurring reminders
   - Active hours boundary conditions (e.g. reminder at 5:59pm with 6pm cutoff)
   - One-time reminders auto-disabling after firing
   - Weekday filtering

### Useful debugging tips
- Use `print()` statements liberally while building — they appear in Xcode's console
- The notification simulator in Xcode can trigger test notifications without waiting
- Check `Console.app` on your Mac for system-level logs if notifications aren't appearing

---

## Phase 4: Deployment

### Option A — Personal use only (recommended to start)
1. In Xcode: Product → Archive
2. In the Organiser window: Distribute App → Copy App
3. Move the exported `.app` to `/Applications`
4. System Settings → General → Login Items → add the app to run at login

### Option B — Share with others (no Apple Developer account)
1. Follow Option A steps to export the `.app`
2. Right-click the `.app` → Compress to create a `.zip`
3. Share the `.zip` — recipients must right-click → Open the first time to bypass Gatekeeper
4. Note: recipients may see an "unidentified developer" warning

### Option C — Mac App Store / wide distribution
- Requires Apple Developer Program membership ($99/year at developer.apple.com)
- Additional steps: code signing, entitlements, App Sandbox, notarization, App Store review
- Recommended only if you plan to distribute publicly at scale

---

## Reference: key files in the Xcode project

| File | Purpose |
|------|---------|
| `YourAppApp.swift` | App entry point, sets up menubar agent |
| `ReminderStore.swift` | Observable data store, persistence |
| `SchedulingEngine.swift` | Calculates and fires triggers |
| `NotificationManager.swift` | Handles UNUserNotificationCenter |
| `ContentView.swift` | Root SwiftUI view (dropdown panel) |
| `ReminderListView.swift` | Reminder list + tabs |
| `ReminderDetailView.swift` | Detail view for a selected reminder |
| `ReminderFormView.swift` | Add/Edit form |
| `Info.plist` | App configuration (LSUIElement = YES) |

---

## Useful resources
- [Apple Human Interface Guidelines — menubar extras](https://developer.apple.com/design/human-interface-guidelines/menu-bar-extras)
- [UNUserNotificationCenter docs](https://developer.apple.com/documentation/usernotifications)
- [SwiftUI tutorials (Apple)](https://developer.apple.com/tutorials/swiftui)
- [Hacking with Swift — free SwiftUI reference](https://www.hackingwithswift.com/quick-start/swiftui)
