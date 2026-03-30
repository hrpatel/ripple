# Ripple — Phase 2, Steps 1 & 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a menubar-only macOS app shell with a bell icon and popover panel, backed by a data layer that persists reminders as JSON on disk.

**Architecture:** AppDelegate owns NSStatusItem (menubar icon) and NSPopover (panel), and creates ReminderStore directly. ReminderStore is injected into SwiftUI views via `.environment()` (Swift Observation). PersistenceManager is a stateless utility that reads/writes a JSON file in Application Support and accepts an injectable URL so it can be unit tested.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit (NSStatusItem, NSPopover, NSHostingController), Foundation (FileManager, JSONEncoder/Decoder), XCTest for unit tests.

---

## File Map

| Status | Path | Responsibility |
|--------|------|----------------|
| Modify | `Ripple/RippleApp.swift` | @main entry; wires in AppDelegate, no WindowGroup |
| Create | `Ripple/AppDelegate.swift` | NSStatusItem + NSPopover + ReminderStore; toggle logic |
| Modify | `Ripple/ContentView.swift` | Placeholder 320×400 panel view |
| Create | `Ripple/Models/Reminder.swift` | All model structs and enums |
| Create | `Ripple/Store/PersistenceManager.swift` | JSON load/save to Application Support |
| Create | `Ripple/Store/ReminderStore.swift` | ObservableObject; CRUD + auto-save |
| Create | `RippleTests/PersistenceManagerTests.swift` | Unit tests for file I/O |
| Create | `RippleTests/ReminderStoreTests.swift` | Unit tests for store CRUD |

---

### Task 1: Create and configure the Xcode project

**Files:**
- Create: `Ripple.xcodeproj` (via Xcode GUI)
- Create: `Ripple/RippleApp.swift` (auto-generated)
- Create: `Ripple/ContentView.swift` (auto-generated)

- [ ] **Step 1: Open Xcode and create a new project**

  1. Open Xcode
  2. Choose **File → New → Project...**
  3. Select the **macOS** tab → **App** → click **Next**
  4. Fill in:
     - **Product Name:** `Ripple`
     - **Interface:** SwiftUI
     - **Language:** Swift
     - **Uncheck** "Include Tests" (we add these manually in Task 6)
  5. Click **Next**
  6. In the save dialog, navigate to `/Users/hpatel/Revisions/ripple/`
  7. **Uncheck** "Create Git repository on my Mac" (one already exists there)
  8. Click **Create**

- [ ] **Step 2: Verify the default build succeeds**

  Press **⌘B**.
  Expected: "Build Succeeded" banner at the top of Xcode.

- [ ] **Step 3: Set LSUIElement = YES (hides Dock icon)**

  1. In the Project Navigator (left panel), click the **Ripple** blue project icon at the very top
  2. Under **TARGETS**, select **Ripple**
  3. Click the **Info** tab
  4. In the **Custom macOS Application Target Properties** table, hover over any row and click the **+** button that appears
  5. Type `Application is agent (UIElement)` and press Enter
  6. In the Value column for that row, click and select **YES**

- [ ] **Step 4: Verify no Dock icon on launch**

  Press **⌘R** to run.
  Expected: The app starts, no Ripple icon appears in the Dock. A default "Hello World" window may open — that's fine for now. Press **⌘.** to stop.

- [ ] **Step 5: Commit the Xcode project to git**

  Open Terminal.app and run:
  ```bash
  cd /Users/hpatel/Revisions/ripple
  git add Ripple/ Ripple.xcodeproj/
  git commit -m "feat: add Xcode project scaffold (Phase 1)"
  ```

---

### Task 2: Update RippleApp.swift

**Files:**
- Modify: `Ripple/RippleApp.swift`

The generated file has a `WindowGroup` which creates an app window. Replace it with `Settings { EmptyView() }` — a no-op scene that satisfies SwiftUI without opening any window. Add `@NSApplicationDelegateAdaptor` to wire in AppDelegate.

- [ ] **Step 1: Open RippleApp.swift**

  In the Project Navigator, click **Ripple → RippleApp.swift**

- [ ] **Step 2: Replace the entire file with:**

  ```swift
  import SwiftUI

  @main
  struct RippleApp: App {
      @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

      var body: some Scene {
          Settings { EmptyView() }
      }
  }
  ```

- [ ] **Step 3: Build**

  Press **⌘B**.
  Expected: Error "Cannot find type 'AppDelegate'" — this is expected. We create it next.

---

### Task 3: Create AppDelegate.swift

**Files:**
- Create: `Ripple/AppDelegate.swift`

AppDelegate handles all AppKit work: creates the menubar icon, creates the popover, and owns the ReminderStore. When the icon is clicked, it toggles the popover open or closed.

- [ ] **Step 1: Create a new Swift file**

  1. In the Project Navigator, right-click the **Ripple** folder → **New File...**
  2. Select **Swift File** → click **Next**
  3. Name it `AppDelegate` → click **Create**
  4. Make sure the **Ripple** target checkbox is checked in the dialog

- [ ] **Step 2: Replace the file contents with:**

  ```swift
  import AppKit
  import SwiftUI

  class AppDelegate: NSObject, NSApplicationDelegate {
      var statusItem: NSStatusItem!
      var popover: NSPopover!
      var store = ReminderStore()

      func applicationDidFinishLaunching(_ notification: Notification) {
          setupMenubarIcon()
          setupPopover()
      }

      private func setupMenubarIcon() {
          statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
          if let button = statusItem.button {
              button.image = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Ripple")
              button.action = #selector(togglePopover)
              button.target = self
          }
      }

      private func setupPopover() {
          popover = NSPopover()
          popover.contentSize = NSSize(width: 320, height: 400)
          popover.behavior = .transient
          popover.contentViewController = NSHostingController(
              rootView: ContentView().environment(store)
          )
      }

      @objc private func togglePopover() {
          guard let button = statusItem.button else { return }
          if popover.isShown {
              popover.performClose(nil)
          } else {
              popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
              popover.contentViewController?.view.window?.makeKey()
          }
      }
  }
  ```

  > Note: `ReminderStore` doesn't exist yet — Xcode will show an error until Task 8. That's expected. The `SchedulerEngine` environment and `engine` property are added later in the scheduling engine step (Step 3).

- [ ] **Step 3: Build (expect error)**

  Press **⌘B**.
  Expected: Error "Cannot find type 'ReminderStore'". Normal — fixed in Task 8.

---

### Task 4: Update ContentView.swift (placeholder)

**Files:**
- Modify: `Ripple/ContentView.swift`

Replace the default "Hello, World!" view with a fixed-size placeholder that matches the popover dimensions.

- [ ] **Step 1: Open ContentView.swift**

  In the Project Navigator, click **Ripple → ContentView.swift**

- [ ] **Step 2: Replace the entire file with:**

  ```swift
  import SwiftUI

  struct ContentView: View {
      var body: some View {
          VStack {
              Text("Hello, Ripple!")
                  .font(.headline)
          }
          .frame(width: 320, height: 400)
      }
  }
  ```

- [ ] **Step 3: Build**

  Press **⌘B**.
  Expected: Still the "Cannot find type 'ReminderStore'" error. Normal.

---

### Task 5: Create Reminder.swift (data model)

**Files:**
- Create: `Ripple/Models/Reminder.swift`

- [ ] **Step 1: Create a Models group**

  In the Project Navigator, right-click the **Ripple** folder → **New Group** → name it `Models`

- [ ] **Step 2: Create Reminder.swift inside the Models group**

  1. Right-click the **Models** group → **New File...**
  2. Select **Swift File** → **Next**
  3. Name it `Reminder` → **Create**
  4. Make sure the **Ripple** target checkbox is checked

- [ ] **Step 3: Replace the file contents with:**

  ```swift
  import Foundation

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

  enum ReminderType: String, Codable {
      case recurring
      case oneTime
  }

  struct DeliveryOptions: Codable {
      var notification: Bool
      var sound: Bool
      var menubarIconFlash: Bool
  }

  /// Monday = 1. Note: this differs from `Calendar.weekday` (where Sunday = 1).
  /// Use `Weekday.rawValue` only for persistence; convert explicitly when comparing with Calendar.
  enum Weekday: Int, Codable, CaseIterable {
      case mon = 1, tue, wed, thu, fri, sat, sun
  }

  extension Reminder {
      var isValid: Bool {
          switch type {
          case .recurring: return intervalMinutes != nil
          case .oneTime:   return scheduledDate != nil
          }
      }
  }
  ```

- [ ] **Step 4: Build**

  Press **⌘B**.
  Expected: Still fails on `ReminderStore`. That's fine.

- [ ] **Step 5: Commit progress**

  ```bash
  cd /Users/hpatel/Revisions/ripple
  git add Ripple/
  git commit -m "feat: add app shell scaffold and data model structs"
  ```

---

### Task 6: Add Unit Testing Bundle

**Files:**
- Creates: `RippleTests/` (via Xcode GUI)

- [ ] **Step 1: Add a Unit Testing Bundle target**

  1. In Xcode, go to **File → New → Target...**
  2. Select the **macOS** tab → **Unit Testing Bundle** → **Next**
  3. Set **Product Name:** `RippleTests`
  4. Confirm **Target to be Tested** is set to **Ripple**
  5. Click **Finish**
  6. If Xcode asks "Activate scheme?", click **Activate**

- [ ] **Step 2: Delete the auto-generated placeholder file**

  In the Project Navigator, find **RippleTests → RippleTests.swift**, right-click it → **Delete** → **Move to Trash**

- [ ] **Step 3: Run tests to confirm the bundle works**

  Press **⌘U** to run all tests.
  Expected: "Test Succeeded" with 0 tests executed (no errors).

---

### Task 7: PersistenceManager — TDD

**Files:**
- Create: `Ripple/Store/PersistenceManager.swift`
- Create: `RippleTests/PersistenceManagerTests.swift`

- [ ] **Step 1: Create a Store group**

  In the Project Navigator, right-click the **Ripple** folder → **New Group** → name it `Store`

- [ ] **Step 2: Create PersistenceManagerTests.swift in RippleTests**

  1. Right-click the **RippleTests** folder → **New File...**
  2. Select **Swift File** → **Next**
  3. Name it `PersistenceManagerTests` → **Create**
  4. Make sure the **RippleTests** target checkbox is checked (and NOT the Ripple target)

- [ ] **Step 3: Write the failing tests**

  Replace the file contents with:

  ```swift
  import XCTest
  @testable import Ripple

  final class PersistenceManagerTests: XCTestCase {
      var tempURL: URL!

      override func setUp() {
          super.setUp()
          tempURL = FileManager.default.temporaryDirectory
              .appendingPathComponent(UUID().uuidString)
              .appendingPathComponent("reminders.json")
      }

      override func tearDown() {
          try? FileManager.default.removeItem(at: tempURL.deletingLastPathComponent())
          super.tearDown()
      }

      func test_load_returnsEmptyArray_whenFileDoesNotExist() {
          let result = PersistenceManager.load(from: tempURL)
          XCTAssertEqual(result.count, 0)
      }

      func test_saveAndLoad_roundtrips() {
          let reminder = Reminder(
              id: UUID(),
              title: "Drink water",
              type: .recurring,
              intervalMinutes: 30,
              scheduledDate: nil,
              activeHoursStart: nil,
              activeHoursEnd: nil,
              activeDays: Set([.mon, .wed]),
              isEnabled: true,
              delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
              snoozeEnabled: false
          )
          PersistenceManager.save([reminder], to: tempURL)
          let loaded = PersistenceManager.load(from: tempURL)
          XCTAssertEqual(loaded.count, 1)
          XCTAssertEqual(loaded.first?.title, "Drink water")
          XCTAssertEqual(loaded.first?.intervalMinutes, 30)
          XCTAssertEqual(loaded.first?.activeDays, [.mon, .wed])
      }

      func test_save_overwritesPreviousData() {
          let first = Reminder(
              id: UUID(), title: "First", type: .oneTime,
              intervalMinutes: nil, scheduledDate: nil,
              activeHoursStart: nil, activeHoursEnd: nil,
              activeDays: nil, isEnabled: true,
              delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
              snoozeEnabled: false
          )
          let second = Reminder(
              id: UUID(), title: "Second", type: .oneTime,
              intervalMinutes: nil, scheduledDate: nil,
              activeHoursStart: nil, activeHoursEnd: nil,
              activeDays: nil, isEnabled: true,
              delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
              snoozeEnabled: false
          )
          PersistenceManager.save([first], to: tempURL)
          PersistenceManager.save([second], to: tempURL)
          let loaded = PersistenceManager.load(from: tempURL)
          XCTAssertEqual(loaded.count, 1)
          XCTAssertEqual(loaded.first?.title, "Second")
      }
  }
  ```

- [ ] **Step 4: Run tests to confirm compile error**

  Press **⌘U**.
  Expected: Compile error "Cannot find type 'PersistenceManager'". This confirms the tests are wired correctly and targeting code that doesn't exist yet.

- [ ] **Step 5: Create PersistenceManager.swift in the Store group**

  1. Right-click the **Store** group → **New File...**
  2. Select **Swift File** → **Next**
  3. Name it `PersistenceManager` → **Create**
  4. Make sure the **Ripple** target checkbox is checked (NOT RippleTests)

- [ ] **Step 6: Write the implementation**

  ```swift
  import Foundation

  struct PersistenceManager {
      static let defaultURL: URL = {
          let support = FileManager.default.urls(
              for: .applicationSupportDirectory,
              in: .userDomainMask
          ).first!
          let dir = support.appendingPathComponent("Ripple", isDirectory: true)
          return dir.appendingPathComponent("reminders.json")
      }()

      static func load(from url: URL = defaultURL) -> [Reminder] {
          guard FileManager.default.fileExists(atPath: url.path) else { return [] }
          do {
              let data = try Data(contentsOf: url)
              return try JSONDecoder().decode([Reminder].self, from: data)
          } catch {
              print("PersistenceManager load error: \(error)")
              return []
          }
      }

      static func save(_ reminders: [Reminder], to url: URL = defaultURL) {
          do {
              let dir = url.deletingLastPathComponent()
              try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
              let data = try JSONEncoder().encode(reminders)
              try data.write(to: url, options: .atomic)
          } catch {
              print("PersistenceManager save error: \(error)")
          }
      }
  }
  ```

- [ ] **Step 7: Run tests to confirm they pass**

  Press **⌘U**.
  Expected: All 3 `PersistenceManagerTests` pass with green checkmarks.

- [ ] **Step 8: Commit**

  ```bash
  cd /Users/hpatel/Revisions/ripple
  git add Ripple/Store/PersistenceManager.swift RippleTests/PersistenceManagerTests.swift
  git commit -m "feat: add PersistenceManager with JSON load/save"
  ```

---

### Task 8: ReminderStore — TDD

**Files:**
- Create: `Ripple/Store/ReminderStore.swift`
- Create: `RippleTests/ReminderStoreTests.swift`

- [ ] **Step 1: Create ReminderStoreTests.swift in RippleTests**

  1. Right-click the **RippleTests** folder → **New File...**
  2. Select **Swift File** → **Next**
  3. Name it `ReminderStoreTests` → **Create**
  4. Make sure the **RippleTests** target checkbox is checked (NOT Ripple)

- [ ] **Step 2: Write the failing tests**

  ```swift
  import XCTest
  @testable import Ripple

  final class ReminderStoreTests: XCTestCase {
      var tempURL: URL!
      var store: ReminderStore!

      override func setUp() {
          super.setUp()
          tempURL = FileManager.default.temporaryDirectory
              .appendingPathComponent(UUID().uuidString)
              .appendingPathComponent("reminders.json")
          store = ReminderStore(persistenceURL: tempURL)
      }

      override func tearDown() {
          try? FileManager.default.removeItem(at: tempURL.deletingLastPathComponent())
          super.tearDown()
      }

      func test_init_loadsEmptyWhenNoFile() {
          XCTAssertEqual(store.reminders.count, 0)
      }

      func test_add_appendsReminder() {
          let r = makeReminder(title: "Stand up")
          store.add(r)
          XCTAssertEqual(store.reminders.count, 1)
          XCTAssertEqual(store.reminders.first?.title, "Stand up")
      }

      func test_add_persistsReminder() {
          let r = makeReminder(title: "Hydrate")
          store.add(r)
          let reloaded = ReminderStore(persistenceURL: tempURL)
          XCTAssertEqual(reloaded.reminders.first?.title, "Hydrate")
      }

      func test_delete_removesReminder() {
          let r = makeReminder(title: "Break")
          store.add(r)
          store.delete(r)
          XCTAssertEqual(store.reminders.count, 0)
      }

      func test_update_replacesReminder() {
          var r = makeReminder(title: "Original")
          store.add(r)
          r.title = "Updated"
          store.update(r)
          XCTAssertEqual(store.reminders.first?.title, "Updated")
      }

      // MARK: - Helpers

      private func makeReminder(title: String) -> Reminder {
          Reminder(
              id: UUID(),
              title: title,
              type: .recurring,
              intervalMinutes: 30,
              scheduledDate: nil,
              activeHoursStart: nil,
              activeHoursEnd: nil,
              activeDays: Set([.mon]),
              isEnabled: true,
              delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
              snoozeEnabled: false
          )
      }
  }
  ```

- [ ] **Step 3: Run tests to confirm compile error**

  Press **⌘U**.
  Expected: Compile error "Cannot find type 'ReminderStore'".

- [ ] **Step 4: Create ReminderStore.swift in the Store group**

  1. Right-click the **Store** group → **New File...**
  2. Select **Swift File** → **Next**
  3. Name it `ReminderStore` → **Create**
  4. Make sure the **Ripple** target checkbox is checked (NOT RippleTests)

- [ ] **Step 5: Write the implementation**

  ```swift
  import Foundation
  import Observation

  @Observable
  final class ReminderStore {
      var reminders: [Reminder]
      var notificationsBlocked = false
      private let persistenceURL: URL

      init(persistenceURL: URL = PersistenceManager.defaultURL) {
          self.persistenceURL = persistenceURL
          self.reminders = PersistenceManager.load(from: persistenceURL)
      }

      func add(_ reminder: Reminder) {
          reminders.append(reminder)
          save()
      }

      func update(_ reminder: Reminder) {
          guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
          reminders[index] = reminder
          save()
      }

      func delete(_ reminder: Reminder) {
          reminders.removeAll { $0.id == reminder.id }
          save()
      }

      private func save() {
          PersistenceManager.save(reminders, to: persistenceURL)
      }
  }
  ```

- [ ] **Step 6: Run all tests**

  Press **⌘U**.
  Expected: All 5 `ReminderStoreTests` pass AND all 3 `PersistenceManagerTests` still pass (8 total).

- [ ] **Step 7: Commit**

  ```bash
  cd /Users/hpatel/Revisions/ripple
  git add Ripple/Store/ReminderStore.swift RippleTests/ReminderStoreTests.swift
  git commit -m "feat: add ReminderStore with CRUD and auto-save"
  ```

---

### Task 9: Build and verify the complete app

Now all files exist. Build the app, run it, and verify both success criteria.

- [ ] **Step 1: Build the full project**

  Press **⌘B**.
  Expected: "Build Succeeded" — no errors. (There may be minor warnings — those are okay.)

- [ ] **Step 2: Run the app**

  Press **⌘R**.

- [ ] **Step 3: Verify Step 1 success criteria (app shell)**

  - [ ] A bell icon appears in the Mac menubar (top-right area of your screen)
  - [ ] No Ripple icon appears in the Dock
  - [ ] Clicking the bell icon shows a panel with "Hello, Ripple!"
  - [ ] Clicking the icon again (or clicking anywhere outside the panel) closes it

- [ ] **Step 4: Verify Step 2 success criteria (persistence)**

  In Terminal.app:
  ```bash
  ls ~/Library/Application\ Support/Ripple/
  ```
  Expected: `reminders.json` exists.

  ```bash
  cat ~/Library/Application\ Support/Ripple/reminders.json
  ```
  Expected: `[]` (empty array — no reminders added yet via UI, but the file exists and is valid JSON).

- [ ] **Step 5: Stop the app**

  Press **⌘.** in Xcode, or click the square stop button.

- [ ] **Step 6: Final commit**

  ```bash
  cd /Users/hpatel/Revisions/ripple
  git add -A
  git commit -m "feat: complete Phase 2 Steps 1 & 2 — app shell and data layer"
  ```

---

**Steps 1 & 2 complete.** Next up: Step 3 (scheduling engine), which fires reminders based on interval, active hours, and active days.
