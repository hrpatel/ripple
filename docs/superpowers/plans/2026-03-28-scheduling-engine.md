# Scheduling Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a tick-based in-process scheduler that fires reminders every 60 seconds and delivers via system notification, sound, and menubar flash.

**Architecture:** `SchedulerEngine` owns a 60-second `Timer`, evaluates fire conditions on each tick, and delegates delivery to `DeliveryManager`. `AppDelegate` owns both objects and wires them at launch. Snooze is handled via a `UNNotificationAction` callback.

**Tech Stack:** Swift 5.9+, Foundation (Timer, UUID), UserNotifications (UNUserNotificationCenter), AppKit (NSSound, NSStatusBarButton), XCTest.

---

## File Map


| Status | Path                                      | Responsibility                                                                 |
| ------ | ----------------------------------------- | ------------------------------------------------------------------------------ |
| Create | `Ripple/Scheduling/SchedulerEngine.swift` | 60-second timer, fire conditions, snooze tracking                              |
| Create | `Ripple/Scheduling/DeliveryManager.swift` | `DeliveryManagerProtocol` + implementation: notification, sound, menubar flash |
| Modify | `Ripple/AppDelegate.swift`                | Add `engine` + `delivery` properties, `setupScheduler()`                       |
| Create | `RippleTests/SchedulerEngineTests.swift`  | Unit tests for all fire conditions                                             |


---

### Task 1: Scaffold — protocol, engine skeleton, test boilerplate

**Files:**

- Create: `Ripple/Scheduling/DeliveryManager.swift`
- Create: `Ripple/Scheduling/SchedulerEngine.swift`
- Create: `RippleTests/SchedulerEngineTests.swift`
- **Step 1: Create the Scheduling group in Xcode**
  In the Project Navigator, right-click the **Ripple** folder → **New Group** → name it `Scheduling`
- **Step 2: Create DeliveryManager.swift in the Scheduling group**
  Right-click **Scheduling** → **New File...** → **Swift File** → name it `DeliveryManager` → **Create**
  Confirm **Ripple** target is checked, NOT RippleTests.
  Replace the file contents with:
  ```swift
  import Foundation

  protocol DeliveryManagerProtocol {
      func deliver(_ reminder: Reminder)
  }
  ```
- **Step 3: Create SchedulerEngine.swift in the Scheduling group**
  Right-click **Scheduling** → **New File...** → **Swift File** → name it `SchedulerEngine` → **Create**
  Confirm **Ripple** target is checked, NOT RippleTests.
  Replace the file contents with:
  ```swift
  import Foundation

  final class SchedulerEngine {
      private let store: ReminderStore
      private let delivery: DeliveryManagerProtocol
      private let now: () -> Date
      private var timer: Timer?
      private var lastFired: [UUID: Date] = [:]
      private var snoozedUntil: [UUID: Date] = [:]

      init(
          store: ReminderStore,
          delivery: DeliveryManagerProtocol,
          now: @escaping () -> Date = Date.init
      ) {
          self.store = store
          self.delivery = delivery
          self.now = now
      }

      func start() {
          timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
              self?.checkAndFire()
          }
      }

      func stop() {
          timer?.invalidate()
          timer = nil
      }

      func snooze(_ id: UUID) {
          snoozedUntil[id] = now().addingTimeInterval(5 * 60)
      }

      func checkAndFire() {
          // implemented in Tasks 2–5
      }
  }
  ```
- **Step 4: Create SchedulerEngineTests.swift in RippleTests**
  Right-click **RippleTests** → **New File...** → **Swift File** → name it `SchedulerEngineTests` → **Create**
  Confirm **RippleTests** target is checked, NOT Ripple.
  Replace the file contents with:
  ```swift
  import XCTest
  @testable import Ripple

  // MARK: - Spy

  final class SpyDelivery: DeliveryManagerProtocol {
      var delivered: [Reminder] = []
      func deliver(_ reminder: Reminder) {
          delivered.append(reminder)
      }
  }

  // MARK: - Tests

  final class SchedulerEngineTests: XCTestCase {
      var tempURL: URL!
      var store: ReminderStore!
      var spy: SpyDelivery!
      var engine: SchedulerEngine!

      override func setUp() {
          super.setUp()
          tempURL = FileManager.default.temporaryDirectory
              .appendingPathComponent(UUID().uuidString)
              .appendingPathComponent("reminders.json")
          store = ReminderStore(persistenceURL: tempURL)
          spy = SpyDelivery()
          engine = SchedulerEngine(store: store, delivery: spy)
      }

      override func tearDown() {
          try? FileManager.default.removeItem(at: tempURL.deletingLastPathComponent())
          super.tearDown()
      }

      // MARK: - Helpers

      private func makeRecurring(
          intervalMinutes: Int = 30,
          activeHoursStart: Int? = nil,
          activeHoursEnd: Int? = nil,
          activeDays: Set<Weekday>? = nil
      ) -> Reminder {
          Reminder(
              id: UUID(),
              title: "Test Recurring",
              type: .recurring,
              intervalMinutes: intervalMinutes,
              scheduledDate: nil,
              activeHoursStart: activeHoursStart,
              activeHoursEnd: activeHoursEnd,
              activeDays: activeDays,
              isEnabled: true,
              delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
              snoozeEnabled: false
          )
      }

      private func makeOneTime(scheduledDate: Date) -> Reminder {
          Reminder(
              id: UUID(),
              title: "Test One-Time",
              type: .oneTime,
              intervalMinutes: nil,
              scheduledDate: scheduledDate,
              activeHoursStart: nil,
              activeHoursEnd: nil,
              activeDays: nil,
              isEnabled: true,
              delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
              snoozeEnabled: false
          )
      }
  }
  ```
- **Step 5: Build to confirm everything compiles**
  Press **⌘B**.
  Expected: "Build Succeeded" — no errors.

---

### Task 2: Recurring interval logic (TDD)

**Files:**

- Modify: `RippleTests/SchedulerEngineTests.swift` — add 2 tests
- Modify: `Ripple/Scheduling/SchedulerEngine.swift` — implement interval check
- **Step 1: Add the failing tests**
  Add these two test methods inside `SchedulerEngineTests`, after the helpers:
  ```swift
  func test_recurring_firesWhenDue() {
      let reminder = makeRecurring(intervalMinutes: 30)
      store.add(reminder)
      engine.checkAndFire()
      XCTAssertEqual(spy.delivered.count, 1)
  }

  func test_recurring_doesNotFireBeforeInterval() {
      let reminder = makeRecurring(intervalMinutes: 30)
      store.add(reminder)
      engine.checkAndFire()   // first fire — sets lastFired
      spy.delivered.removeAll()
      engine.checkAndFire()   // immediately again — interval not elapsed
      XCTAssertEqual(spy.delivered.count, 0)
  }
  ```
- **Step 2: Run tests to confirm they fail**
  Press **⌘U**.
  Expected: Both new tests FAIL — `test_recurring_firesWhenDue` fails because `checkAndFire()` does nothing (delivered.count = 0, not 1).
- **Step 3: Implement interval check in SchedulerEngine**
  Replace `checkAndFire()` and add helper methods in `SchedulerEngine.swift`:
  ```swift
  func checkAndFire() {
      let current = now()

      for reminder in store.reminders {
          guard reminder.isEnabled else { continue }

          switch reminder.type {
          case .recurring:
              guard shouldFireRecurring(reminder, at: current) else { continue }
              lastFired[reminder.id] = current
              delivery.deliver(reminder)
          case .oneTime:
              break  // implemented in Task 5
          }
      }
  }

  private func shouldFireRecurring(_ reminder: Reminder, at date: Date) -> Bool {
      guard let intervalMinutes = reminder.intervalMinutes else { return false }

      if let last = lastFired[reminder.id] {
          let elapsedMinutes = date.timeIntervalSince(last) / 60
          guard elapsedMinutes >= Double(intervalMinutes) else { return false }
      }

      return true
  }

  private func weekdayFromCalendar(_ calendarWeekday: Int) -> Weekday {
      // Calendar.weekday: Sun=1, Mon=2, Tue=3, Wed=4, Thu=5, Fri=6, Sat=7
      // Weekday enum:     Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7
      switch calendarWeekday {
      case 1: return .sun
      case 2: return .mon
      case 3: return .tue
      case 4: return .wed
      case 5: return .thu
      case 6: return .fri
      default: return .sat
      }
  }
  ```
- **Step 4: Run tests to confirm they pass**
  Press **⌘U**.
  Expected: `test_recurring_firesWhenDue` and `test_recurring_doesNotFireBeforeInterval` both pass.
- **Step 5: Commit**
  ```bash
  cd /Users/hpatel/Revisions/ripple
  git add Ripple/Scheduling/ RippleTests/SchedulerEngineTests.swift
  git commit -m "feat: add SchedulerEngine scaffold and recurring interval logic"
  ```

---

### Task 3: Active hours, active days, and disabled (TDD)

**Files:**

- Modify: `RippleTests/SchedulerEngineTests.swift` — add 4 tests
- Modify: `Ripple/Scheduling/SchedulerEngine.swift` — add active hours/days checks
- **Step 1: Add the failing tests**
  Add these four test methods to `SchedulerEngineTests`:
  ```swift
  func test_recurring_respectsActiveHours() {
      // 08:00 on 2026-03-28 — before the 09:00–17:00 active window
      var c = DateComponents()
      c.year = 2026; c.month = 3; c.day = 28; c.hour = 8; c.minute = 0
      let earlyMorning = Calendar.current.date(from: c)!

      let e = SchedulerEngine(store: store, delivery: spy, now: { earlyMorning })
      let reminder = makeRecurring(intervalMinutes: 30, activeHoursStart: 540, activeHoursEnd: 1020)
      store.add(reminder)

      e.checkAndFire()
      XCTAssertEqual(spy.delivered.count, 0)
  }

  func test_recurring_respectsActiveDays() {
      // 2026-03-28 is a Saturday — reminder only active Mon–Fri
      var c = DateComponents()
      c.year = 2026; c.month = 3; c.day = 28; c.hour = 10; c.minute = 0
      let saturday = Calendar.current.date(from: c)!

      let e = SchedulerEngine(store: store, delivery: spy, now: { saturday })
      let reminder = makeRecurring(intervalMinutes: 30, activeDays: [.mon, .tue, .wed, .thu, .fri])
      store.add(reminder)

      e.checkAndFire()
      XCTAssertEqual(spy.delivered.count, 0)
  }

  func test_recurring_allDaysWhenActiveDaysNil() {
      // Same Saturday — activeDays nil means every day passes
      var c = DateComponents()
      c.year = 2026; c.month = 3; c.day = 28; c.hour = 10; c.minute = 0
      let saturday = Calendar.current.date(from: c)!

      let e = SchedulerEngine(store: store, delivery: spy, now: { saturday })
      let reminder = makeRecurring(intervalMinutes: 30, activeDays: nil)
      store.add(reminder)

      e.checkAndFire()
      XCTAssertEqual(spy.delivered.count, 1)
  }

  func test_disabled_neverFires() {
      var reminder = makeRecurring(intervalMinutes: 30)
      reminder.isEnabled = false
      store.add(reminder)
      engine.checkAndFire()
      XCTAssertEqual(spy.delivered.count, 0)
  }
  ```
- **Step 2: Run tests to confirm the new ones fail**
  Press **⌘U**.
  Expected: `test_recurring_respectsActiveHours` and `test_recurring_respectsActiveDays` FAIL (fire when they shouldn't). `test_recurring_allDaysWhenActiveDaysNil` passes (by coincidence — no day check yet). `test_disabled_neverFires` passes (guard already in place).
- **Step 3: Add active hours and days checks to shouldFireRecurring**
  Replace the entire `shouldFireRecurring` method in `SchedulerEngine.swift`:
  ```swift
  private func shouldFireRecurring(_ reminder: Reminder, at date: Date) -> Bool {
      guard let intervalMinutes = reminder.intervalMinutes else { return false }

      // Active days check
      if let activeDays = reminder.activeDays {
          let calWeekday = Calendar.current.component(.weekday, from: date)
          guard activeDays.contains(weekdayFromCalendar(calWeekday)) else { return false }
      }

      // Active hours check (assumes start <= end, no overnight ranges)
      if let start = reminder.activeHoursStart, let end = reminder.activeHoursEnd {
          let h = Calendar.current.component(.hour, from: date)
          let m = Calendar.current.component(.minute, from: date)
          let mins = h * 60 + m
          guard mins >= start && mins <= end else { return false }
      }

      // Interval elapsed check
      if let last = lastFired[reminder.id] {
          let elapsedMinutes = date.timeIntervalSince(last) / 60
          guard elapsedMinutes >= Double(intervalMinutes) else { return false }
      }

      return true
  }
  ```
- **Step 4: Run tests to confirm all pass**
  Press **⌘U**.
  Expected: All tests pass, including the 4 new ones.
- **Step 5: Commit**
  ```bash
  cd /Users/hpatel/Revisions/ripple
  git add Ripple/Scheduling/SchedulerEngine.swift RippleTests/SchedulerEngineTests.swift
  git commit -m "feat: add active hours, active days, and disabled checks to SchedulerEngine"
  ```

---

### Task 4: Snooze (TDD)

**Files:**

- Modify: `RippleTests/SchedulerEngineTests.swift` — add 2 tests
- Modify: `Ripple/Scheduling/SchedulerEngine.swift` — snooze is already wired; verify it works
- **Step 1: Add the failing tests**
  Add these two test methods to `SchedulerEngineTests`:
  ```swift
  func test_recurring_skipsWhenSnoozed() {
      let reminder = makeRecurring(intervalMinutes: 30)
      store.add(reminder)
      engine.snooze(reminder.id)
      engine.checkAndFire()
      XCTAssertEqual(spy.delivered.count, 0)
  }

  func test_recurring_firesAfterSnoozeExpires() {
      let base = Date()
      var time = base
      let e = SchedulerEngine(store: store, delivery: spy, now: { time })

      let reminder = makeRecurring(intervalMinutes: 30)
      store.add(reminder)

      e.snooze(reminder.id)
      e.checkAndFire()
      XCTAssertEqual(spy.delivered.count, 0)

      // Advance 6 minutes — past the 5-minute snooze window
      time = base.addingTimeInterval(6 * 60)
      e.checkAndFire()
      XCTAssertEqual(spy.delivered.count, 1)
  }
  ```
- **Step 2: Run tests to confirm they fail**
  Press **⌘U**.
  Expected: Both snooze tests FAIL — snooze logic is stubbed in but `snoozedUntil` filtering in `checkAndFire` uses `now()`, so the timing may not work correctly until fully verified.
- **Step 3: Add snooze filtering to checkAndFire**
  Replace `checkAndFire()` in `SchedulerEngine.swift` with:
  ```swift
  func checkAndFire() {
      let current = now()
      snoozedUntil = snoozedUntil.filter { $0.value > current }

      for reminder in store.reminders {
          guard reminder.isEnabled else { continue }
          guard snoozedUntil[reminder.id] == nil else { continue }

          switch reminder.type {
          case .recurring:
              guard shouldFireRecurring(reminder, at: current) else { continue }
              lastFired[reminder.id] = current
              delivery.deliver(reminder)
          case .oneTime:
              break  // implemented in Task 5
          }
      }
  }
  ```
- **Step 4: Run tests to confirm all pass**
  Press **⌘U**.
  Expected: All tests pass.
- **Step 5: Commit**
  ```bash
  cd /Users/hpatel/Revisions/ripple
  git add Ripple/Scheduling/SchedulerEngine.swift RippleTests/SchedulerEngineTests.swift
  git commit -m "feat: verify snooze logic in SchedulerEngine"
  ```

---

### Task 5: One-time reminders (TDD)

**Files:**

- Modify: `RippleTests/SchedulerEngineTests.swift` — add 1 test
- Modify: `Ripple/Scheduling/SchedulerEngine.swift` — implement one-time case
- **Step 1: Add the failing test**
  Add this test method to `SchedulerEngineTests`:
  ```swift
  func test_oneTime_firesAndDisables() {
      let past = Date().addingTimeInterval(-60)  // 1 minute ago
      let reminder = makeOneTime(scheduledDate: past)
      store.add(reminder)

      engine.checkAndFire()

      XCTAssertEqual(spy.delivered.count, 1)
      XCTAssertFalse(store.reminders.first!.isEnabled)
  }
  ```
- **Step 2: Run test to confirm it fails**
  Press **⌘U**.
  Expected: `test_oneTime_firesAndDisables` FAIL — the `.oneTime` case is a `break` and does nothing.
- **Step 3: Implement the one-time case in checkAndFire**
  In `SchedulerEngine.swift`, replace the `case .oneTime: break` line inside `checkAndFire()`:
  ```swift
  case .oneTime:
      guard let scheduledDate = reminder.scheduledDate, current >= scheduledDate else { continue }
      var updated = reminder
      updated.isEnabled = false
      store.update(updated)
      delivery.deliver(reminder)
  ```
- **Step 4: Run tests to confirm all 9 pass**
  Press **⌘U**.
  Expected: All 9 tests pass — 0 failures.
- **Step 5: Commit**
  ```bash
  cd /Users/hpatel/Revisions/ripple
  git add Ripple/Scheduling/SchedulerEngine.swift RippleTests/SchedulerEngineTests.swift
  git commit -m "feat: add one-time reminder fire-and-disable to SchedulerEngine"
  ```

---

### Task 6: DeliveryManager implementation

**Files:**

- Modify: `Ripple/Scheduling/DeliveryManager.swift` — full implementation
- **Step 1: Replace DeliveryManager.swift with the full implementation**
  ```swift
  import AppKit
  import UserNotifications

  protocol DeliveryManagerProtocol {
      func deliver(_ reminder: Reminder)
  }

  final class DeliveryManager: NSObject, DeliveryManagerProtocol {
      private weak var statusButton: NSStatusBarButton?
      private let onSnooze: (UUID) -> Void

      init(statusButton: NSStatusBarButton?, onSnooze: @escaping (UUID) -> Void) {
          self.statusButton = statusButton
          self.onSnooze = onSnooze
          super.init()
          UNUserNotificationCenter.current().delegate = self
      }

      func requestAuthorization() {
          let snoozeAction = UNNotificationAction(identifier: "SNOOZE", title: "Snooze")
          let category = UNNotificationCategory(
              identifier: "REMINDER",
              actions: [snoozeAction],
              intentIdentifiers: []
          )
          UNUserNotificationCenter.current().setNotificationCategories([category])
          UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
      }

      func deliver(_ reminder: Reminder) {
          if reminder.delivery.notification {
              sendNotification(for: reminder)
          }
          if reminder.delivery.sound {
              NSSound(named: .init("Glass"))?.play()
          }
          if reminder.delivery.menubarIconFlash {
              flashMenubarIcon()
          }
      }

      private func sendNotification(for reminder: Reminder) {
          let content = UNMutableNotificationContent()
          content.title = reminder.title
          if reminder.snoozeEnabled {
              content.categoryIdentifier = "REMINDER"
          }
          let request = UNNotificationRequest(
              identifier: reminder.id.uuidString,
              content: content,
              trigger: nil
          )
          UNUserNotificationCenter.current().add(request)
      }

      private func flashMenubarIcon() {
          var count = 0
          Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
              count += 1
              let filled = count % 2 == 0
              self?.statusButton?.image = NSImage(
                  systemSymbolName: filled ? "bell.fill" : "bell",
                  accessibilityDescription: nil
              )
              if count >= 8 {
                  timer.invalidate()
                  self?.statusButton?.image = NSImage(
                      systemSymbolName: "bell.fill",
                      accessibilityDescription: nil
                  )
              }
          }
      }
  }

  extension DeliveryManager: UNUserNotificationCenterDelegate {
      func userNotificationCenter(
          _ center: UNUserNotificationCenter,
          didReceive response: UNNotificationResponse,
          withCompletionHandler completionHandler: @escaping () -> Void
      ) {
          if response.actionIdentifier == "SNOOZE",
             let id = UUID(uuidString: response.notification.request.identifier) {
              onSnooze(id)
          }
          completionHandler()
      }

      func userNotificationCenter(
          _ center: UNUserNotificationCenter,
          willPresent notification: UNNotification,
          withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
      ) {
          completionHandler([.banner, .sound])
      }
  }
  ```
- **Step 2: Build to confirm it compiles**
  Press **⌘B**.
  Expected: "Build Succeeded".
- **Step 3: Commit**
  ```bash
  cd /Users/hpatel/Revisions/ripple
  git add Ripple/Scheduling/DeliveryManager.swift
  git commit -m "feat: add DeliveryManager with notification, sound, and menubar flash"
  ```

---

### Task 7: Wire into AppDelegate

**Files:**

- Modify: `Ripple/AppDelegate.swift`
- **Step 1: Replace AppDelegate.swift with the wired version**
  ```swift
  import AppKit
  import SwiftUI

  class AppDelegate: NSObject, NSApplicationDelegate {
      var statusItem: NSStatusItem!
      var popover: NSPopover!
      var store = ReminderStore()
      var engine: SchedulerEngine!
      var delivery: DeliveryManager!

      func applicationDidFinishLaunching(_ notification: Notification) {
          setupMenubarIcon()
          setupPopover()
          setupScheduler()
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

      private func setupScheduler() {
          delivery = DeliveryManager(statusButton: statusItem.button) { [weak self] id in
              self?.engine.snooze(id)
          }
          delivery.requestAuthorization()
          engine = SchedulerEngine(store: store, delivery: delivery)
          engine.start()
      }

      @objc private func togglePopover() {
          guard let button = statusItem.button, popover != nil else { return }
          if popover.isShown {
              popover.performClose(nil)
          } else {
              popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
              popover.contentViewController?.view.window?.makeKey()
          }
      }
  }
  ```
- **Step 2: Build and run**
  Press **⌘B** — Expected: "Build Succeeded".
  Press **⌘R** — Expected: Bell icon appears in menubar, no Dock icon.
- **Step 3: Verify notification permission prompt**
  On first launch macOS should show a notification permission dialog: **"Ripple" Would Like to Send You Notifications**. Click **Allow**.
  If the dialog does not appear, open **System Settings → Notifications → Ripple** and enable notifications manually.
- **Step 4: Smoke test a reminder firing**
  In Xcode's debugger console, verify the engine started by looking for no crash output. To quickly test delivery without waiting 30 minutes, you can temporarily add a test reminder directly in `setupScheduler()`:
  ```swift
  // SMOKE TEST ONLY — remove after verifying
  let test = Reminder(
      id: UUID(), title: "Test Fire", type: .recurring,
      intervalMinutes: 1, scheduledDate: nil,
      activeHoursStart: nil, activeHoursEnd: nil, activeDays: nil,
      isEnabled: true,
      delivery: DeliveryOptions(notification: true, sound: true, menubarIconFlash: true),
      snoozeEnabled: true
  )
  store.add(test)
  ```
  Wait ~60 seconds. Expected: a system notification titled "Test Fire" appears with a Snooze button, the Glass sound plays, and the menubar bell flashes.
  Remove the smoke test code after verifying.
- **Step 5: Stop the app and commit**
  Press **⌘.** to stop.
  ```bash
  cd /Users/hpatel/Revisions/ripple
  git add Ripple/AppDelegate.swift
  git commit -m "feat: wire SchedulerEngine and DeliveryManager into AppDelegate"
  ```

