# Ripple — Phase 2, Steps 1 & 2 Design
**Date:** 2026-03-27
**Scope:** App shell (menubar icon + popover) and data model + persistence layer

---

## Prerequisites

Phase 1 must be completed before starting:
1. Create Xcode project (macOS App, SwiftUI, Swift, no tests for now)
2. Set `LSUIElement = YES` in `Info.plist` to hide from Dock
3. Git initialized in the project folder

---

## Architecture

```
RippleApp (@main)
 └── @NSApplicationDelegateAdaptor → AppDelegate
      ├── NSStatusItem  (menubar icon — bell SF Symbol)
      ├── NSPopover     (dropdown panel, 320×400)
      └── ReminderStore (@StateObject, injected via .environmentObject)
           ├── [Reminder]          (in-memory array)
           └── PersistenceManager  (read/write JSON to Application Support)
```

**Approach:** SwiftUI `@main` App struct with `NSApplicationDelegateAdaptor`. AppKit concerns (status item, popover lifecycle) live in `AppDelegate`. SwiftUI concerns (views, data bindings) use the environment system.

---

## File Structure

```
Ripple/
  RippleApp.swift             — @main entry; wires in AppDelegate and ReminderStore
  AppDelegate.swift           — NSStatusItem + NSPopover setup and toggle logic
  ContentView.swift           — Placeholder SwiftUI root view (320×400)
  Models/
    Reminder.swift            — All model structs and enums
  Store/
    ReminderStore.swift       — @MainActor ObservableObject; CRUD + auto-save
    PersistenceManager.swift  — JSON encode/decode to ~/Library/Application Support/Ripple/
```

---

## Step 1 — App Shell

### Goal
A running app with a bell icon in the menubar. Clicking it toggles a small panel open/closed. No Dock icon, no app window.

### `RippleApp.swift`
- Standard `@main` SwiftUI App struct
- Declares `@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate`
- Creates `@StateObject var store = ReminderStore()`
- No `WindowGroup` — the body is `Settings {}` (an empty scene, required by SwiftUI but unused)
- Injects `store` into the environment so `AppDelegate` can pass it to the popover

### `AppDelegate.swift`
- Conforms to `NSObject, NSApplicationDelegate`
- On `applicationDidFinishLaunching`:
  - Creates `NSStatusItem` with a fixed length
  - Sets the status button image to `NSImage(systemSymbolName: "bell.fill", ...)`
  - Creates `NSPopover`, sets `contentSize` to `320×400`, `behavior` to `.transient` (clicking outside closes it)
  - Sets `contentViewController` to an `NSHostingController` wrapping `ContentView()`
  - Attaches a click target to the status button that calls `togglePopover()`
- `togglePopover()` — if popover is shown, closes it; otherwise shows it relative to the status button

### `ContentView.swift`
- Placeholder only: a `VStack` containing `Text("Hello, Ripple!")`, fixed frame `320×400`
- Will be replaced with the full UI in Steps 7–8

### Success Criteria
- Build succeeds (⌘B)
- Bell icon appears in the menubar
- Clicking the icon shows/hides the panel
- No icon in the Dock
- No separate app window

---

## Step 2 — Data Model + Persistence

### Goal
Reminders are defined, stored in memory, and survive app restarts via a JSON file on disk.

### `Models/Reminder.swift`
Exact structs from the project brief — no changes:

```swift
struct Reminder: Identifiable, Codable {
    var id: UUID
    var title: String
    var type: ReminderType
    var intervalMinutes: Int?
    var scheduledDate: Date?
    var activeHoursStart: Date?
    var activeHoursEnd: Date?
    var activeDays: Set<Weekday>
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

### `Store/PersistenceManager.swift`
A plain struct with two static functions (no state, no init needed):

- `static func load() -> [Reminder]`
  - Resolves path: `~/Library/Application Support/Ripple/reminders.json`
  - If file does not exist, returns `[]`
  - Reads file data, decodes `[Reminder]` with `JSONDecoder`
  - On decode failure, logs error and returns `[]` (never crashes)

- `static func save(_ reminders: [Reminder])`
  - Resolves same path
  - Creates the `Ripple/` directory if it does not exist (`FileManager.createDirectory`)
  - Encodes `[Reminder]` with `JSONEncoder` (`.prettyPrinted` for readability during development)
  - Writes to file, overwriting any existing file

### `Store/ReminderStore.swift`
An `@MainActor` `ObservableObject` that is the single source of truth for reminder data:

- `@Published var reminders: [Reminder]`
- `init()` — calls `PersistenceManager.load()` and assigns the result to `reminders`
- `func add(_ reminder: Reminder)` — appends to array, calls `save()`
- `func update(_ reminder: Reminder)` — replaces the element with matching `id`, calls `save()`
- `func delete(_ reminder: Reminder)` — removes the element with matching `id`, calls `save()`
- Private `save()` — calls `PersistenceManager.save(reminders)`

### Wiring into the App
In `RippleApp.swift`, the `ReminderStore` is created as a `@StateObject`. Because `AppDelegate` is initialized by the system (not by us), we can't pass `store` via a normal init parameter. Instead, we give `AppDelegate` a `var store: ReminderStore?` property, and in `RippleApp.body` we set `appDelegate.store = store` so the delegate has a reference to it. The delegate then passes `store` into `ContentView` via `.environmentObject(store)` on the `NSHostingController`, making it available to all SwiftUI views inside the popover.

### Success Criteria
- App compiles with all model types defined
- Hardcoded test reminder added at launch persists after quit and relaunch
- JSON file visible at `~/Library/Application Support/Ripple/reminders.json`

---

## What This Does Not Cover
Steps 3–10 (scheduling engine, notifications, sound, menubar flash, full SwiftUI UI, snooze, polish) are out of scope for this spec.
