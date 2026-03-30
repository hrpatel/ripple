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
      └── ReminderStore (@Observable, injected via .environment)
           ├── [Reminder]          (in-memory array)
           └── PersistenceManager  (read/write JSON to Application Support)
```

**Approach:** SwiftUI `@main` App struct with `NSApplicationDelegateAdaptor`. AppKit concerns (status item, popover lifecycle) live in `AppDelegate`. SwiftUI concerns (views, data bindings) use the Swift Observation framework (`@Observable`) and `.environment()` injection.

---

## File Structure

```
Ripple/
  RippleApp.swift             — @main entry; wires in AppDelegate
  AppDelegate.swift           — NSStatusItem + NSPopover setup, owns ReminderStore
  ContentView.swift           — Placeholder SwiftUI root view (320×400)
  Models/
    Reminder.swift            — All model structs and enums
  Store/
    ReminderStore.swift       — @Observable class; CRUD + auto-save
    PersistenceManager.swift  — JSON encode/decode to ~/Library/Application Support/Ripple/
```

---

## Step 1 — App Shell

### Goal
A running app with a bell icon in the menubar. Clicking it toggles a small panel open/closed. No Dock icon, no app window.

### `RippleApp.swift`
- Standard `@main` SwiftUI App struct
- Declares `@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate`
- No `WindowGroup` — the body is `Settings { EmptyView() }` (an empty scene, required by SwiftUI but unused)
- `AppDelegate` creates and owns the `ReminderStore` directly

### `AppDelegate.swift`
- Conforms to `NSObject, NSApplicationDelegate`
- On `applicationDidFinishLaunching`:
  - Creates `NSStatusItem` with a square length
  - Sets the status button image to `NSImage(systemSymbolName: "bell.fill", ...)`
  - Creates `NSPopover`, sets `contentSize` to `320×400`, `behavior` to `.transient` (clicking outside closes it)
  - Sets `contentViewController` to an `NSHostingController` wrapping `ContentView()` with `.environment(store)` and `.environment(\.schedulerEngine, engine)`
  - Attaches a click target to the status button that calls `togglePopover()`
- `togglePopover()` — if popover is shown, closes it; otherwise shows it relative to the status button; makes the popover window key so it receives keyboard focus

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
Based on the project brief with refinements — active hours use `Int?` (minutes since midnight) instead of `Date?` for simpler comparison logic, and `activeDays` is optional (nil = every day):

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
    var snoozeEnabled: Bool
}

enum ReminderType: String, Codable { case recurring, oneTime }

struct DeliveryOptions: Codable {
    var notification: Bool
    var sound: Bool
    var menubarIconFlash: Bool
}

/// Monday = 1. Note: this differs from `Calendar.weekday` (where Sunday = 1).
/// Use `Weekday.rawValue` only for persistence; convert explicitly when comparing with Calendar.
enum Weekday: Int, Codable, CaseIterable {
    case mon=1, tue, wed, thu, fri, sat, sun
}
```

Also includes an `isValid` computed property for form validation:
- `.recurring` requires `intervalMinutes != nil`
- `.oneTime` requires `scheduledDate != nil`

### `Store/PersistenceManager.swift`
A plain struct with two static functions and a `defaultURL` constant (no state, no init needed). Both functions accept an injectable URL parameter (defaults to `defaultURL`) so tests can use a temp file:

- `static let defaultURL: URL` — resolves to `~/Library/Application Support/Ripple/reminders.json`

- `static func load(from url: URL = defaultURL) -> [Reminder]`
  - If file does not exist, returns `[]`
  - Reads file data, decodes `[Reminder]` with `JSONDecoder`
  - On decode failure, logs error and returns `[]` (never crashes)

- `static func save(_ reminders: [Reminder], to url: URL = defaultURL)`
  - Creates the `Ripple/` directory if it does not exist (`FileManager.createDirectory`)
  - Encodes `[Reminder]` with `JSONEncoder`
  - Writes to file atomically, overwriting any existing file

### `Store/ReminderStore.swift`
An `@Observable` class that is the single source of truth for reminder data:

- `var reminders: [Reminder]`
- `var notificationsBlocked = false` — transient flag set when notification permission is denied (not persisted)
- `init(persistenceURL:)` — accepts an injectable URL (defaults to `PersistenceManager.defaultURL`) for testability; calls `PersistenceManager.load(from:)` and assigns the result to `reminders`
- `func add(_ reminder: Reminder)` — appends to array, calls `save()`
- `func update(_ reminder: Reminder)` — replaces the element with matching `id`, calls `save()`
- `func delete(_ reminder: Reminder)` — removes the element with matching `id`, calls `save()`
- Private `save()` — calls `PersistenceManager.save(reminders)`

### Wiring into the App
`AppDelegate` creates `ReminderStore` directly as a stored property (`var store = ReminderStore()`). It then passes `store` into `ContentView` via `.environment(store)` on the `NSHostingController`, making it available to all SwiftUI views inside the popover. Views access it with `@Environment(ReminderStore.self) var store`.

### Success Criteria
- App compiles with all model types defined
- Hardcoded test reminder added at launch persists after quit and relaunch
- JSON file visible at `~/Library/Application Support/Ripple/reminders.json`

---

## What This Does Not Cover
Steps 3–10 (scheduling engine, notifications, sound, menubar flash, full SwiftUI UI, snooze, polish) are out of scope for this spec.
