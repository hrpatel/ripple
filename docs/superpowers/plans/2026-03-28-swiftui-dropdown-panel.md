# SwiftUI Dropdown Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the placeholder ContentView with a reminder list (tabs, toggles, badges) and a navigation-pushed detail view showing all reminder metadata and next trigger time.

**Architecture:** `ContentView` wraps a `NavigationStack`. `ReminderListView` is the root (header + segmented tab bar + filtered list). Each row is a `ReminderRowView` (toggle + title + subtitle + badge). Tapping a row pushes `ReminderDetailView` (info fields + delivery tags). `SchedulerEngine` gets a `nextFireDate(for:)` method exposed to views via a custom `EnvironmentKey`.

**Tech Stack:** SwiftUI (NavigationStack, List, Toggle, Picker), Foundation (DateFormatter, Calendar), Observation (@Observable environment).

---

## File Map

| Status | Path | Responsibility |
|--------|------|----------------|
| Create | `Ripple/Extensions/Reminder+Formatting.swift` | Display helpers: subtitle, hours, days, interval labels |
| Create | `Ripple/Views/ReminderRowView.swift` | Single row: toggle, title, subtitle, badge |
| Create | `Ripple/Views/ReminderListView.swift` | Header, tab bar, filtered list, empty states |
| Create | `Ripple/Views/ReminderDetailView.swift` | Info fields, delivery tags, edit button placeholder |
| Modify | `Ripple/ContentView.swift` | NavigationStack + SchedulerEngine EnvironmentKey |
| Modify | `Ripple/Scheduling/SchedulerEngine.swift` | Add `nextFireDate(for:)` |
| Modify | `Ripple/AppDelegate.swift` | Reorder setup, pass engine via environment |
| Modify | `RippleTests/SchedulerEngineTests.swift` | Tests for `nextFireDate(for:)` |

---

### Task 1: Add `nextFireDate(for:)` to SchedulerEngine (TDD)

**Files:**
- Modify: `RippleTests/SchedulerEngineTests.swift` — add 4 tests
- Modify: `Ripple/Scheduling/SchedulerEngine.swift` — add method

- [ ] **Step 1: Add the failing tests**

  Add these four test methods to `SchedulerEngineTests`, after the existing tests:

  ```swift
  // MARK: - Task 1: Next fire date tests

  func test_nextFireDate_recurring_neverFired() {
      let reminder = makeRecurring(intervalMinutes: 30)
      store.add(reminder)
      let next = engine.nextFireDate(for: reminder)
      XCTAssertNotNil(next)
      XCTAssertEqual(next!.timeIntervalSince1970, currentTime.timeIntervalSince1970, accuracy: 1)
  }

  func test_nextFireDate_recurring_afterFire() {
      let reminder = makeRecurring(intervalMinutes: 30)
      store.add(reminder)
      engine.checkAndFire()  // fires once, sets lastFired to currentTime
      let next = engine.nextFireDate(for: reminder)
      XCTAssertNotNil(next)
      let expected = currentTime.addingTimeInterval(30 * 60)
      XCTAssertEqual(next!.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 1)
  }

  func test_nextFireDate_oneTime() {
      let future = Date().addingTimeInterval(3600)
      let reminder = makeOneTime(scheduledDate: future)
      XCTAssertEqual(engine.nextFireDate(for: reminder), future)
  }

  func test_nextFireDate_disabled_returnsNil() {
      var reminder = makeRecurring(intervalMinutes: 30)
      reminder.isEnabled = false
      XCTAssertNil(engine.nextFireDate(for: reminder))
  }
  ```

- [ ] **Step 2: Run tests to confirm they fail**

  Press **⌘U**.
  Expected: All 4 new tests FAIL — `nextFireDate` does not exist yet.

- [ ] **Step 3: Implement `nextFireDate(for:)` in SchedulerEngine**

  Add this method to `SchedulerEngine`, after `checkAndFire()`:

  ```swift
  func nextFireDate(for reminder: Reminder) -> Date? {
      guard reminder.isEnabled else { return nil }

      switch reminder.type {
      case .recurring:
          guard let interval = reminder.intervalMinutes else { return nil }
          if let last = lastFired[reminder.id] {
              return last.addingTimeInterval(Double(interval) * 60)
          }
          return now()
      case .oneTime:
          return reminder.scheduledDate
      }
  }
  ```

- [ ] **Step 4: Run tests to confirm all pass**

  Press **⌘U**.
  Expected: All 13 SchedulerEngine tests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add Ripple/Scheduling/SchedulerEngine.swift RippleTests/SchedulerEngineTests.swift
  git commit -m "feat: add nextFireDate(for:) to SchedulerEngine"
  ```

---

### Task 2: Add formatting helpers

**Files:**
- Create: `Ripple/Extensions/Reminder+Formatting.swift`

- [ ] **Step 1: Create the Extensions directory and file**

  Create `Ripple/Extensions/Reminder+Formatting.swift` with:

  ```swift
  import Foundation

  extension Reminder {
      /// Subtitle for list rows — e.g. "Every 45 min · 9am–6pm" or "Today at 10:00 AM"
      var subtitle: String {
          switch type {
          case .recurring:
              let interval = intervalLabel
              let hours = activeHoursLabel
              return hours == "All day" ? interval : "\(interval) · \(hours)"
          case .oneTime:
              guard let date = scheduledDate else { return "" }
              if Calendar.current.isDateInToday(date) {
                  let formatter = DateFormatter()
                  formatter.dateFormat = "'Today at' h:mm a"
                  return formatter.string(from: date)
              }
              let formatter = DateFormatter()
              formatter.dateFormat = "MMM d 'at' h:mm a"
              return formatter.string(from: date)
          }
      }

      /// "Every 45 min" or "Every 2 hr"
      var intervalLabel: String {
          guard let mins = intervalMinutes else { return "" }
          if mins >= 60 && mins % 60 == 0 {
              return "Every \(mins / 60) hr"
          }
          return "Every \(mins) min"
      }

      /// "9am – 5pm" or "All day"
      var activeHoursLabel: String {
          guard let start = activeHoursStart, let end = activeHoursEnd else { return "All day" }
          return "\(formatMinutes(start)) – \(formatMinutes(end))"
      }

      /// "Mon – Fri" or "Every day" or "Mon, Wed, Fri"
      var activeDaysLabel: String {
          guard let days = activeDays else { return "Every day" }
          if days.count == 7 { return "Every day" }
          let weekdays: Set<Weekday> = [.mon, .tue, .wed, .thu, .fri]
          if days == weekdays { return "Mon – Fri" }
          let sorted = days.sorted { $0.rawValue < $1.rawValue }
          return sorted.map { $0.shortName }.joined(separator: ", ")
      }

      private func formatMinutes(_ totalMinutes: Int) -> String {
          let h = totalMinutes / 60
          let m = totalMinutes % 60
          let period = h < 12 ? "am" : "pm"
          let displayH: Int
          if h == 0 { displayH = 12 }
          else if h > 12 { displayH = h - 12 }
          else { displayH = h }
          if m == 0 {
              return "\(displayH)\(period)"
          }
          return String(format: "%d:%02d%@", displayH, m, period)
      }
  }

  extension Weekday {
      var shortName: String {
          switch self {
          case .mon: return "Mon"
          case .tue: return "Tue"
          case .wed: return "Wed"
          case .thu: return "Thu"
          case .fri: return "Fri"
          case .sat: return "Sat"
          case .sun: return "Sun"
          }
      }
  }
  ```

- [ ] **Step 2: Build to confirm it compiles**

  Press **⌘B**.
  Expected: "Build Succeeded".

- [ ] **Step 3: Commit**

  ```bash
  git add Ripple/Extensions/Reminder+Formatting.swift
  git commit -m "feat: add Reminder display formatting helpers"
  ```

---

### Task 3: Create ReminderRowView

**Files:**
- Create: `Ripple/Views/ReminderRowView.swift`

- [ ] **Step 1: Create the Views directory and file**

  Create `Ripple/Views/ReminderRowView.swift` with:

  ```swift
  import SwiftUI

  struct ReminderRowView: View {
      let reminder: Reminder
      let onToggle: (Bool) -> Void

      var body: some View {
          HStack(spacing: 10) {
              Toggle("", isOn: Binding(
                  get: { reminder.isEnabled },
                  set: { onToggle($0) }
              ))
              .toggleStyle(.switch)
              .labelsHidden()
              .controlSize(.small)

              VStack(alignment: .leading, spacing: 2) {
                  Text(reminder.title)
                      .fontWeight(.medium)
                  Text(reminder.subtitle)
                      .font(.caption)
                      .foregroundStyle(.secondary)
              }

              Spacer()

              Text(reminder.type == .recurring ? "recurring" : "one-time")
                  .font(.caption2)
                  .fontWeight(.medium)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 3)
                  .background(
                      Capsule()
                          .fill(reminder.type == .recurring
                              ? Color.green.opacity(0.2)
                              : Color.teal.opacity(0.2))
                  )
                  .foregroundStyle(reminder.type == .recurring ? .green : .teal)
          }
          .padding(.vertical, 4)
      }
  }
  ```

- [ ] **Step 2: Build to confirm it compiles**

  Press **⌘B**.
  Expected: "Build Succeeded".

- [ ] **Step 3: Commit**

  ```bash
  git add Ripple/Views/ReminderRowView.swift
  git commit -m "feat: add ReminderRowView with toggle, title, subtitle, badge"
  ```

---

### Task 4: Create ReminderListView

**Files:**
- Create: `Ripple/Views/ReminderListView.swift`

- [ ] **Step 1: Create the file**

  Create `Ripple/Views/ReminderListView.swift` with:

  ```swift
  import SwiftUI

  enum ReminderFilter: String, CaseIterable {
      case all = "All"
      case active = "Active"
      case paused = "Paused"
  }

  struct ReminderListView: View {
      @Environment(ReminderStore.self) var store
      @State private var selectedFilter: ReminderFilter = .all

      var filteredReminders: [Reminder] {
          switch selectedFilter {
          case .all: return store.reminders
          case .active: return store.reminders.filter { $0.isEnabled }
          case .paused: return store.reminders.filter { !$0.isEnabled }
          }
      }

      var body: some View {
          VStack(spacing: 0) {
              // Header
              HStack {
                  Text("Reminders")
                      .font(.headline)
                  Spacer()
                  Button("+ Add") { }
                      .buttonStyle(.plain)
                      .foregroundStyle(.blue)
              }
              .padding(.horizontal)
              .padding(.top, 12)
              .padding(.bottom, 8)

              // Tab bar
              Picker("Filter", selection: $selectedFilter) {
                  ForEach(ReminderFilter.allCases, id: \.self) { filter in
                      Text(filter.rawValue).tag(filter)
                  }
              }
              .pickerStyle(.segmented)
              .padding(.horizontal)
              .padding(.bottom, 8)

              // List or empty state
              if filteredReminders.isEmpty {
                  Spacer()
                  Text(emptyMessage)
                      .foregroundStyle(.secondary)
                      .font(.subheadline)
                  Spacer()
              } else {
                  List(filteredReminders) { reminder in
                      NavigationLink(value: reminder.id) {
                          ReminderRowView(reminder: reminder) { newValue in
                              var updated = reminder
                              updated.isEnabled = newValue
                              store.update(updated)
                          }
                      }
                  }
                  .listStyle(.plain)
              }
          }
      }

      private var emptyMessage: String {
          switch selectedFilter {
          case .all: return "No reminders yet"
          case .active: return "No active reminders"
          case .paused: return "No paused reminders"
          }
      }
  }
  ```

- [ ] **Step 2: Build to confirm it compiles**

  Press **⌘B**.
  Expected: "Build Succeeded".

- [ ] **Step 3: Commit**

  ```bash
  git add Ripple/Views/ReminderListView.swift
  git commit -m "feat: add ReminderListView with tabs, filter, and empty states"
  ```

---

### Task 5: Create ReminderDetailView

**Files:**
- Create: `Ripple/Views/ReminderDetailView.swift`

- [ ] **Step 1: Create the file**

  Create `Ripple/Views/ReminderDetailView.swift` with:

  ```swift
  import SwiftUI

  struct ReminderDetailView: View {
      let reminder: Reminder
      @Environment(\.schedulerEngine) var engine

      var body: some View {
          VStack(alignment: .leading, spacing: 16) {
              // Header
              VStack(alignment: .leading, spacing: 4) {
                  Text(reminder.title)
                      .font(.title2)
                      .fontWeight(.bold)
                  Text(reminder.type == .recurring ? "Recurring reminder" : "One-time reminder")
                      .foregroundStyle(.secondary)
              }

              Divider()

              // Info fields
              if reminder.type == .recurring {
                  infoGrid(rows: [
                      ("INTERVAL", reminder.intervalLabel),
                      ("ACTIVE HOURS", reminder.activeHoursLabel),
                      ("DAYS", reminder.activeDaysLabel),
                      ("NEXT TRIGGER", nextTriggerLabel),
                  ])
              } else {
                  infoGrid(rows: [
                      ("SCHEDULED", scheduledLabel),
                      ("STATUS", reminder.isEnabled ? "Pending" : "Fired"),
                  ])
              }

              Divider()

              // Delivery tags
              Text("DELIVERY")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              HStack(spacing: 8) {
                  deliveryTag("Notification", isActive: reminder.delivery.notification)
                  deliveryTag("Sound", isActive: reminder.delivery.sound)
                  deliveryTag("Menubar Icon", isActive: reminder.delivery.menubarIconFlash)
              }

              Spacer()

              // Edit button placeholder
              HStack {
                  Spacer()
                  Button("Edit reminder") { }
                      .buttonStyle(.plain)
                      .foregroundStyle(.blue)
                  Spacer()
              }
          }
          .padding()
      }

      // MARK: - Helpers

      private var nextTriggerLabel: String {
          guard reminder.isEnabled else { return "Paused" }
          guard let next = engine?.nextFireDate(for: reminder) else { return "—" }
          return next.formatted(date: .omitted, time: .shortened)
      }

      private var scheduledLabel: String {
          guard let date = reminder.scheduledDate else { return "—" }
          return date.formatted(date: .abbreviated, time: .shortened)
      }

      private func infoGrid(rows: [(String, String)]) -> some View {
          Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
              ForEach(rows, id: \.0) { label, value in
                  GridRow {
                      Text(label)
                          .font(.caption)
                          .foregroundStyle(.secondary)
                          .frame(minWidth: 100, alignment: .leading)
                      Text(value)
                  }
              }
          }
      }

      private func deliveryTag(_ title: String, isActive: Bool) -> some View {
          Text(title)
              .font(.caption)
              .padding(.horizontal, 10)
              .padding(.vertical, 5)
              .background(
                  Capsule()
                      .fill(isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
              )
              .foregroundStyle(isActive ? .green : .secondary)
      }
  }
  ```

  **Note:** This file references `@Environment(\.schedulerEngine)` which is defined in the next task. It will not compile until Task 6 is done.

- [ ] **Step 2: Commit (will compile after Task 6)**

  ```bash
  git add Ripple/Views/ReminderDetailView.swift
  git commit -m "feat: add ReminderDetailView with info fields and delivery tags"
  ```

---

### Task 6: Update ContentView with NavigationStack and EnvironmentKey

**Files:**
- Modify: `Ripple/ContentView.swift`

- [ ] **Step 1: Replace ContentView.swift**

  Replace the entire contents of `Ripple/ContentView.swift` with:

  ```swift
  import SwiftUI

  // MARK: - SchedulerEngine EnvironmentKey

  struct SchedulerEngineKey: EnvironmentKey {
      static let defaultValue: SchedulerEngine? = nil
  }

  extension EnvironmentValues {
      var schedulerEngine: SchedulerEngine? {
          get { self[SchedulerEngineKey.self] }
          set { self[SchedulerEngineKey.self] = newValue }
      }
  }

  // MARK: - Root View

  struct ContentView: View {
      @Environment(ReminderStore.self) var store

      var body: some View {
          NavigationStack {
              ReminderListView()
                  .navigationDestination(for: UUID.self) { id in
                      if let reminder = store.reminders.first(where: { $0.id == id }) {
                          ReminderDetailView(reminder: reminder)
                      }
                  }
          }
          .frame(minWidth: 320, minHeight: 400)
      }
  }
  ```

- [ ] **Step 2: Build to confirm everything compiles**

  Press **⌘B**.
  Expected: "Build Succeeded" — all new views + environment key are now connected.

- [ ] **Step 3: Commit**

  ```bash
  git add Ripple/ContentView.swift
  git commit -m "feat: update ContentView with NavigationStack and SchedulerEngine environment"
  ```

---

### Task 7: Update AppDelegate to pass engine via environment

**Files:**
- Modify: `Ripple/AppDelegate.swift`

- [ ] **Step 1: Reorder setup and pass engine**

  In `Ripple/AppDelegate.swift`, change `applicationDidFinishLaunching` to call `setupScheduler()` **before** `setupPopover()`:

  ```swift
  func applicationDidFinishLaunching(_ notification: Notification) {
      setupMenubarIcon()
      setupScheduler()
      setupPopover()
  }
  ```

  Then update `setupPopover()` to pass `engine` via environment:

  ```swift
  private func setupPopover() {
      popover = NSPopover()
      popover.contentSize = NSSize(width: 320, height: 400)
      popover.behavior = .transient
      popover.contentViewController = NSHostingController(
          rootView: ContentView()
              .environment(store)
              .environment(\.schedulerEngine, engine)
      )
  }
  ```

- [ ] **Step 2: Build and run**

  Press **⌘B** — Expected: "Build Succeeded".
  Press **⌘R** — Expected: Bell icon appears. Click it to open the popover. You should see "Reminders" header, tab bar (All / Active / Paused), and "No reminders yet" empty state.

- [ ] **Step 3: Commit**

  ```bash
  git add Ripple/AppDelegate.swift
  git commit -m "feat: wire SchedulerEngine environment and reorder AppDelegate setup"
  ```

---

### Task 8: Visual verification

- [ ] **Step 1: Add a smoke-test reminder to verify the list**

  In `setupScheduler()` in `AppDelegate.swift`, temporarily add after `engine.start()`:

  ```swift
  // SMOKE TEST ONLY — remove after verifying
  store.add(Reminder(
      id: UUID(), title: "Stand up", type: .recurring,
      intervalMinutes: 45, scheduledDate: nil,
      activeHoursStart: 540, activeHoursEnd: 1080, activeDays: [.mon, .tue, .wed, .thu, .fri],
      isEnabled: true,
      delivery: DeliveryOptions(notification: true, sound: true, menubarIconFlash: true),
      snoozeEnabled: true
  ))
  store.add(Reminder(
      id: UUID(), title: "Team standup", type: .oneTime,
      intervalMinutes: nil, scheduledDate: Date().addingTimeInterval(3600),
      activeHoursStart: nil, activeHoursEnd: nil, activeDays: nil,
      isEnabled: true,
      delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
      snoozeEnabled: false
  ))
  ```

- [ ] **Step 2: Run and verify**

  Press **⌘R**. Click the bell icon. Verify:
  - Two reminders appear in the list with correct titles, subtitles, and badges
  - Toggle switches work (toggling off moves a reminder to "Paused" tab)
  - Tab filters (All / Active / Paused) show the correct reminders
  - Clicking a row navigates to the detail view with correct info fields and delivery tags
  - Back button returns to the list

- [ ] **Step 3: Remove smoke test and commit**

  Remove the smoke test code, then:

  ```bash
  git add Ripple/AppDelegate.swift
  git commit -m "chore: verify dropdown panel UI"
  ```
