# Add/Edit Reminder Form Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a form view for creating and editing reminders, pushed onto the NavigationStack from the list or detail view.

**Architecture:** `ReminderFormView` manages local `@State` for all fields, constructs a `Reminder` on save, and calls `store.add()` or `store.update()`. Navigation uses a `RippleDestination` enum with a shared `NavigationPath` so the form can pop to root after save/delete. The form adapts between add and edit modes based on whether a `Reminder` is passed.

**Tech Stack:** SwiftUI (Form, Picker, Toggle, DatePicker, TextField, NavigationPath), Foundation.

---

## File Map

| Status | Path | Responsibility |
|--------|------|----------------|
| Modify | `Ripple/Extensions/Reminder+Formatting.swift` | Add `Weekday.letter` for day pill toggles |
| Create | `Ripple/Views/ReminderFormView.swift` | Full add/edit form |
| Modify | `Ripple/ContentView.swift` | Add `RippleDestination` enum, `NavigationPath`, form routing |
| Modify | `Ripple/Views/ReminderListView.swift` | Wire "+ Add" button to push form |
| Modify | `Ripple/Views/ReminderDetailView.swift` | Wire "Edit reminder" button to push form |

---

### Task 1: Add `Weekday.letter` property

**Files:**
- Modify: `Ripple/Extensions/Reminder+Formatting.swift`

- [ ] **Step 1: Add the `letter` property to the Weekday extension**

  In `Ripple/Extensions/Reminder+Formatting.swift`, add this inside the existing `extension Weekday` block, after `shortName`:

  ```swift
  var letter: String {
      switch self {
      case .mon: return "M"
      case .tue: return "T"
      case .wed: return "W"
      case .thu: return "T"
      case .fri: return "F"
      case .sat: return "S"
      case .sun: return "S"
      }
  }
  ```

- [ ] **Step 2: Build to confirm it compiles**

  Press **⌘B**.
  Expected: "Build Succeeded".

- [ ] **Step 3: Commit**

  ```bash
  git add Ripple/Extensions/Reminder+Formatting.swift
  git commit -m "feat: add Weekday.letter for day pill toggles"
  ```

---

### Task 2: Create ReminderFormView

**Files:**
- Create: `Ripple/Views/ReminderFormView.swift`

- [ ] **Step 1: Create the form file**

  Create `Ripple/Views/ReminderFormView.swift` with the complete form:

  ```swift
  import SwiftUI

  struct ReminderFormView: View {
      let reminderToEdit: Reminder?
      @Binding var path: NavigationPath
      @Environment(ReminderStore.self) var store
      @Environment(\.dismiss) var dismiss

      @State private var title: String
      @State private var type: ReminderType
      @State private var intervalSelection: Int
      @State private var customIntervalText: String
      @State private var activeHoursEnabled: Bool
      @State private var activeHoursStart: Int
      @State private var activeHoursEnd: Int
      @State private var activeDays: Set<Weekday>
      @State private var scheduledDate: Date
      @State private var notificationEnabled: Bool
      @State private var soundEnabled: Bool
      @State private var menubarFlashEnabled: Bool
      @State private var snoozeEnabled: Bool

      private let intervalPresets = [15, 30, 45, 60, 90, 120]

      var isEditing: Bool { reminderToEdit != nil }

      init(reminder: Reminder? = nil, path: Binding<NavigationPath>) {
          self.reminderToEdit = reminder
          self._path = path

          _title = State(initialValue: reminder?.title ?? "")
          _type = State(initialValue: reminder?.type ?? .recurring)

          let interval = reminder?.intervalMinutes ?? 30
          if let idx = [15, 30, 45, 60, 90, 120].firstIndex(of: interval) {
              _intervalSelection = State(initialValue: idx)
              _customIntervalText = State(initialValue: "")
          } else {
              _intervalSelection = State(initialValue: -1)
              _customIntervalText = State(initialValue: "\(interval)")
          }

          _activeHoursEnabled = State(initialValue: reminder?.activeHoursStart != nil)
          _activeHoursStart = State(initialValue: reminder?.activeHoursStart ?? 540)
          _activeHoursEnd = State(initialValue: reminder?.activeHoursEnd ?? 1020)
          _activeDays = State(initialValue: reminder?.activeDays ?? Set(Weekday.allCases))
          _scheduledDate = State(initialValue: reminder?.scheduledDate ?? Date().addingTimeInterval(3600))
          _notificationEnabled = State(initialValue: reminder?.delivery.notification ?? true)
          _soundEnabled = State(initialValue: reminder?.delivery.sound ?? false)
          _menubarFlashEnabled = State(initialValue: reminder?.delivery.menubarIconFlash ?? false)
          _snoozeEnabled = State(initialValue: reminder?.snoozeEnabled ?? false)
      }

      var body: some View {
          VStack(spacing: 0) {
              // Header: Cancel + title on one row
              HStack {
                  Button(action: { dismiss() }) {
                      HStack(spacing: 4) {
                          Image(systemName: "chevron.left")
                          Text("Cancel")
                      }
                  }
                  .buttonStyle(.plain)
                  .foregroundStyle(.blue)
                  Spacer()
                  Text(isEditing ? "Edit Reminder" : "Add Reminder")
                      .font(.headline)
                  Spacer()
              }
              .padding(.horizontal)
              .padding(.top, 10)
              .padding(.bottom, 6)

              VStack(alignment: .leading, spacing: 10) {
                  titleSection
                  typeSection
                  if type == .recurring {
                      recurringSection
                  } else {
                      oneTimeSection
                  }
                  deliverySection
                  snoozeSection
              }
              .padding(.horizontal)
              .padding(.bottom, 8)

              Divider()
              footerSection
          }
      }

      // MARK: - Title

      private var titleSection: some View {
          VStack(alignment: .leading, spacing: 4) {
              Text("Title")
                  .font(.subheadline)
                  .fontWeight(.medium)
              TextField("Reminder title", text: $title)
                  .textFieldStyle(.roundedBorder)
          }
      }

      // MARK: - Type

      private var typeSection: some View {
          VStack(alignment: .leading, spacing: 4) {
              Text("Type")
                  .font(.subheadline)
                  .fontWeight(.medium)
              Picker("Type", selection: $type) {
                  Text("Recurring").tag(ReminderType.recurring)
                  Text("One-time").tag(ReminderType.oneTime)
              }
              .pickerStyle(.segmented)
          }
      }

      // MARK: - Recurring fields

      private var recurringSection: some View {
          VStack(alignment: .leading, spacing: 8) {
              // Interval
              HStack {
                  Text("Interval")
                      .font(.subheadline)
                      .fontWeight(.medium)

                  Picker("Interval", selection: $intervalSelection) {
                      ForEach(0..<intervalPresets.count, id: \.self) { idx in
                          Text(intervalPresets[idx] >= 60
                              ? "\(intervalPresets[idx] / 60) hr"
                              : "\(intervalPresets[idx]) min"
                          ).tag(idx)
                      }
                      Text("Custom").tag(-1)
                  }
                  .pickerStyle(.menu)
                  .labelsHidden()
              }

              if intervalSelection == -1 {
                  HStack {
                      TextField("Minutes", text: $customIntervalText)
                          .textFieldStyle(.roundedBorder)
                          .frame(width: 80)
                      Text("minutes")
                          .foregroundStyle(.secondary)
                  }
              }

              // Active hours
              Toggle("Active hours", isOn: $activeHoursEnabled)

              if activeHoursEnabled {
                  HStack {
                      Picker("Start", selection: $activeHoursStart) {
                          ForEach(timeOptions, id: \.self) { minutes in
                              Text(formatTime(minutes)).tag(minutes)
                          }
                      }
                      .labelsHidden()
                      .frame(width: 110)

                      Text("to")
                          .foregroundStyle(.secondary)

                      Picker("End", selection: $activeHoursEnd) {
                          ForEach(timeOptions, id: \.self) { minutes in
                              Text(formatTime(minutes)).tag(minutes)
                          }
                      }
                      .labelsHidden()
                      .frame(width: 110)
                  }
              }

              // Active days
              Text("Active days")
                  .font(.subheadline)
                  .fontWeight(.medium)

              HStack(spacing: 6) {
                  ForEach(Weekday.allCases, id: \.self) { day in
                      Button(action: { toggleDay(day) }) {
                          Text(day.letter)
                              .font(.caption)
                              .fontWeight(.medium)
                              .frame(width: 30, height: 30)
                              .background(
                                  Circle().fill(activeDays.contains(day)
                                      ? Color.blue
                                      : Color.clear)
                              )
                              .foregroundStyle(activeDays.contains(day) ? .white : .primary)
                              .overlay(Circle().stroke(Color.gray.opacity(0.3)))
                      }
                      .buttonStyle(.plain)
                  }
              }
          }
      }

      // MARK: - One-time fields

      private var oneTimeSection: some View {
          VStack(alignment: .leading, spacing: 4) {
              Text("Date & Time")
                  .font(.subheadline)
                  .fontWeight(.medium)
              DatePicker("", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                  .labelsHidden()
          }
      }

      // MARK: - Delivery

      private var deliverySection: some View {
          VStack(alignment: .leading, spacing: 4) {
              Text("Delivery")
                  .font(.subheadline)
                  .fontWeight(.medium)
              Toggle("Notification", isOn: $notificationEnabled)
                  .controlSize(.small)
              Toggle("Sound", isOn: $soundEnabled)
                  .controlSize(.small)
              Toggle("Menubar icon flash", isOn: $menubarFlashEnabled)
                  .controlSize(.small)
          }
      }

      // MARK: - Snooze

      private var snoozeSection: some View {
          Toggle("Snooze (5 min)", isOn: $snoozeEnabled)
              .controlSize(.small)
      }

      // MARK: - Footer

      private var footerSection: some View {
          HStack {
              if isEditing {
                  Button("Delete") { deleteReminder() }
                      .foregroundStyle(.red)
                      .buttonStyle(.plain)
              }

              Spacer()

              Button("Cancel") { dismiss() }
                  .buttonStyle(.plain)

              Button(isEditing ? "Save" : "Add Reminder") { save() }
                  .buttonStyle(.borderedProminent)
                  .disabled(!isValid)
          }
          .padding()
      }

      // MARK: - Computed

      private var resolvedInterval: Int? {
          if intervalSelection >= 0 && intervalSelection < intervalPresets.count {
              return intervalPresets[intervalSelection]
          }
          return Int(customIntervalText)
      }

      private var isValid: Bool {
          let trimmed = title.trimmingCharacters(in: .whitespaces)
          guard !trimmed.isEmpty else { return false }
          switch type {
          case .recurring:
              guard let mins = resolvedInterval, mins > 0 else { return false }
              if activeHoursEnabled && activeHoursStart >= activeHoursEnd { return false }
              return true
          case .oneTime:
              return true
          }
      }

      private var timeOptions: [Int] {
          Array(stride(from: 0, through: 1410, by: 30))
      }

      // MARK: - Actions

      private func save() {
          let finalDays: Set<Weekday>? = (activeDays.count == 7 || activeDays.isEmpty) ? nil : activeDays

          let reminder = Reminder(
              id: reminderToEdit?.id ?? UUID(),
              title: title.trimmingCharacters(in: .whitespaces),
              type: type,
              intervalMinutes: type == .recurring ? resolvedInterval : nil,
              scheduledDate: type == .oneTime ? scheduledDate : nil,
              activeHoursStart: (type == .recurring && activeHoursEnabled) ? activeHoursStart : nil,
              activeHoursEnd: (type == .recurring && activeHoursEnabled) ? activeHoursEnd : nil,
              activeDays: type == .recurring ? finalDays : nil,
              isEnabled: reminderToEdit?.isEnabled ?? true,
              delivery: DeliveryOptions(
                  notification: notificationEnabled,
                  sound: soundEnabled,
                  menubarIconFlash: menubarFlashEnabled
              ),
              snoozeEnabled: snoozeEnabled
          )

          if isEditing {
              store.update(reminder)
          } else {
              store.add(reminder)
          }

          path = NavigationPath()
      }

      private func deleteReminder() {
          if let reminder = reminderToEdit {
              store.delete(reminder)
          }
          path = NavigationPath()
      }

      private func toggleDay(_ day: Weekday) {
          if activeDays.contains(day) {
              activeDays.remove(day)
          } else {
              activeDays.insert(day)
          }
      }

      private func formatTime(_ totalMinutes: Int) -> String {
          let h = totalMinutes / 60
          let m = totalMinutes % 60
          let period = h < 12 ? "AM" : "PM"
          let displayH: Int
          if h == 0 { displayH = 12 }
          else if h > 12 { displayH = h - 12 }
          else { displayH = h }
          return String(format: "%d:%02d %@", displayH, m, period)
      }
  }
  ```

- [ ] **Step 2: Build to confirm it compiles**

  Press **⌘B**.
  Expected: "Build Succeeded". The form compiles standalone — it only references `Reminder`, `ReminderStore`, `Weekday`, `ReminderType`, `DeliveryOptions`, and `NavigationPath`, all of which exist.

- [ ] **Step 3: Commit**

  ```bash
  git add Ripple/Views/ReminderFormView.swift
  git commit -m "feat: add ReminderFormView for creating and editing reminders"
  ```

---

### Task 3: Update navigation routing and wire buttons

**Files:**
- Modify: `Ripple/ContentView.swift`
- Modify: `Ripple/Views/ReminderListView.swift`
- Modify: `Ripple/Views/ReminderDetailView.swift`

- [ ] **Step 1: Update ContentView with RippleDestination and NavigationPath**

  Replace the entire `Ripple/ContentView.swift` with:

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

  // MARK: - Navigation

  enum RippleDestination: Hashable {
      case detail(UUID)
      case form(UUID?)  // nil = add, UUID = edit
  }

  // MARK: - Root View

  struct ContentView: View {
      @Environment(ReminderStore.self) var store
      @State private var path = NavigationPath()

      var body: some View {
          NavigationStack(path: $path) {
              ReminderListView()
                  .navigationDestination(for: RippleDestination.self) { destination in
                      switch destination {
                      case .detail(let id):
                          if let reminder = store.reminders.first(where: { $0.id == id }) {
                              ReminderDetailView(reminder: reminder)
                          }
                      case .form(let id):
                          if let id, let reminder = store.reminders.first(where: { $0.id == id }) {
                              ReminderFormView(reminder: reminder, path: $path)
                          } else {
                              ReminderFormView(path: $path)
                          }
                      }
                  }
          }
          .frame(minWidth: 320, minHeight: 400)
      }
  }
  ```

- [ ] **Step 2: Wire "+ Add" button in ReminderListView**

  In `Ripple/Views/ReminderListView.swift`, replace the "+ Add" button:

  Replace:
  ```swift
  Button("+ Add") { }
      .buttonStyle(.plain)
      .foregroundStyle(.blue)
  ```

  With:
  ```swift
  NavigationLink(value: RippleDestination.form(nil)) {
      Text("+ Add")
  }
  .buttonStyle(.plain)
  .foregroundStyle(.blue)
  ```

  Also replace the `NavigationLink` in the list:

  Replace:
  ```swift
  NavigationLink(value: reminder.id) {
  ```

  With:
  ```swift
  NavigationLink(value: RippleDestination.detail(reminder.id)) {
  ```

- [ ] **Step 3: Wire "Edit reminder" button in ReminderDetailView**

  In `Ripple/Views/ReminderDetailView.swift`, replace the "Edit reminder" button:

  Replace:
  ```swift
  Button("Edit reminder") { }
      .buttonStyle(.plain)
      .foregroundStyle(.blue)
  ```

  With:
  ```swift
  NavigationLink(value: RippleDestination.form(reminder.id)) {
      Text("Edit reminder")
  }
  .buttonStyle(.plain)
  .foregroundStyle(.blue)
  ```

- [ ] **Step 4: Build to confirm everything compiles**

  Press **⌘B**.
  Expected: "Build Succeeded".

- [ ] **Step 5: Commit**

  ```bash
  git add Ripple/ContentView.swift Ripple/Views/ReminderListView.swift Ripple/Views/ReminderDetailView.swift
  git commit -m "feat: wire add/edit form into navigation with RippleDestination routing"
  ```

---

### Task 4: Build, run, and verify

- [ ] **Step 1: Run the app**

  Press **⌘R**. Click the bell icon. Verify the empty state: "No reminders yet" with an "+ Add" button.

- [ ] **Step 2: Test adding a recurring reminder**

  Click "+ Add". Fill in:
  - Title: "Stand up"
  - Type: Recurring
  - Interval: 45 min
  - Active hours: toggle on, 9:00 AM to 5:00 PM
  - Active days: deselect Sat and Sun
  - Delivery: Notification on, Sound on
  - Click "Add Reminder"

  Expected: Returns to list showing the new reminder with correct subtitle and badge.

- [ ] **Step 3: Test adding a one-time reminder**

  Click "+ Add". Fill in:
  - Title: "Team standup"
  - Type: One-time
  - Pick a date/time
  - Click "Add Reminder"

  Expected: Appears in list with "one-time" badge and formatted date subtitle.

- [ ] **Step 4: Test editing a reminder**

  Click a reminder row → detail view → "Edit reminder". Change the title. Click "Save".
  Expected: Returns to list, title is updated.

- [ ] **Step 5: Test deleting a reminder**

  Click a reminder row → detail view → "Edit reminder" → "Delete".
  Expected: Returns to list, reminder is gone.

- [ ] **Step 6: Commit verification**

  ```bash
  git add -A
  git commit -m "chore: verify add/edit form functionality"
  ```
