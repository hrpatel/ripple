# SwiftUI Previews Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `#Preview` blocks with popover-sized frames and multiple named states to all 5 SwiftUI views in Ripple.

**Architecture:** Extract `SchedulerEngineProtocol` so previews avoid real timers. Create shared `Reminder` sample data under `#if DEBUG`. Each view gets multiple `#Preview` blocks showing different states, all constrained to 320pt width.

**Tech Stack:** Swift, SwiftUI `#Preview` macro, `@Observable`, SwiftUI Environment

---

### Task 1: Extract SchedulerEngineProtocol

**Files:**
- Modify: `Ripple/Scheduling/SchedulerEngine.swift`
- Modify: `Ripple/ContentView.swift`

- [ ] **Step 1: Add protocol above the SchedulerEngine class**

In `Ripple/Scheduling/SchedulerEngine.swift`, add this protocol before the class definition:

```swift
protocol SchedulerEngineProtocol {
    func nextFireDate(for reminder: Reminder) -> Date?
}
```

Then add conformance to the existing class — change:

```swift
final class SchedulerEngine {
```

to:

```swift
final class SchedulerEngine: SchedulerEngineProtocol {
```

No other changes to SchedulerEngine — it already has the `nextFireDate(for:)` method.

- [ ] **Step 2: Update the environment key to use the protocol**

In `Ripple/ContentView.swift`, change the environment key and values from `SchedulerEngine?` to the protocol type.

Replace:

```swift
struct SchedulerEngineKey: EnvironmentKey {
    static let defaultValue: SchedulerEngine? = nil
}

extension EnvironmentValues {
    var schedulerEngine: SchedulerEngine? {
        get { self[SchedulerEngineKey.self] }
        set { self[SchedulerEngineKey.self] = newValue }
    }
}
```

with:

```swift
struct SchedulerEngineKey: EnvironmentKey {
    static let defaultValue: (any SchedulerEngineProtocol)? = nil
}

extension EnvironmentValues {
    var schedulerEngine: (any SchedulerEngineProtocol)? {
        get { self[SchedulerEngineKey.self] }
        set { self[SchedulerEngineKey.self] = newValue }
    }
}
```

- [ ] **Step 3: Build to verify nothing broke**

Run:
```bash
xcodebuild build -project Ripple.xcodeproj -scheme Ripple -configuration Debug -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Ripple/Scheduling/SchedulerEngine.swift Ripple/ContentView.swift
git commit -m "refactor: extract SchedulerEngineProtocol for preview support"
```

---

### Task 2: Create sample data and preview stub

**Files:**
- Create: `Ripple/Models/Reminder+SampleData.swift`

- [ ] **Step 1: Create the sample data file**

Create `Ripple/Models/Reminder+SampleData.swift` with the following content:

```swift
#if DEBUG
import Foundation

extension Reminder {
    static let sampleRecurring = Reminder(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        title: "Stretch break",
        type: .recurring,
        intervalMinutes: 45,
        scheduledDate: nil,
        activeHoursStart: 540,   // 9am
        activeHoursEnd: 1020,    // 5pm
        activeDays: [.mon, .tue, .wed, .thu, .fri],
        isEnabled: true,
        delivery: DeliveryOptions(notification: true, sound: true, menubarIconFlash: false),
        snoozeDurationMinutes: 5
    )

    static let sampleOneTime = Reminder(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        title: "Team standup",
        type: .oneTime,
        intervalMinutes: nil,
        scheduledDate: Date().addingTimeInterval(3600),
        activeHoursStart: nil,
        activeHoursEnd: nil,
        activeDays: nil,
        isEnabled: true,
        delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: false),
        snoozeDurationMinutes: nil
    )

    static let samplePaused = Reminder(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        title: "Drink water",
        type: .recurring,
        intervalMinutes: 30,
        scheduledDate: nil,
        activeHoursStart: nil,
        activeHoursEnd: nil,
        activeDays: nil,
        isEnabled: false,
        delivery: DeliveryOptions(notification: true, sound: false, menubarIconFlash: true),
        snoozeDurationMinutes: nil
    )

    static let samples: [Reminder] = [sampleRecurring, sampleOneTime, samplePaused]
}

final class PreviewSchedulerEngine: SchedulerEngineProtocol {
    func nextFireDate(for reminder: Reminder) -> Date? {
        reminder.isEnabled ? Date().addingTimeInterval(900) : nil
    }
}

func previewStore(reminders: [Reminder] = Reminder.samples) -> ReminderStore {
    let store = ReminderStore(persistenceURL: URL(fileURLWithPath: "/dev/null"))
    store.reminders = reminders
    return store
}

func previewStoreBlocked() -> ReminderStore {
    let store = previewStore()
    store.notificationsBlocked = true
    return store
}
#endif
```

- [ ] **Step 2: Build to verify compilation**

Run:
```bash
xcodebuild build -project Ripple.xcodeproj -scheme Ripple -configuration Debug -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Ripple/Models/Reminder+SampleData.swift
git commit -m "feat: add sample data and preview helpers for SwiftUI previews"
```

---

### Task 3: Add previews to ReminderRowView

**Files:**
- Modify: `Ripple/Views/ReminderRowView.swift`

- [ ] **Step 1: Add preview blocks at the bottom of the file**

Append the following to the end of `Ripple/Views/ReminderRowView.swift`:

```swift
// MARK: - Previews

#if DEBUG
#Preview("Enabled Recurring") {
    ReminderRowView(reminder: .sampleRecurring) { _ in }
        .frame(width: 320)
        .padding()
}

#Preview("Enabled One-Time") {
    ReminderRowView(reminder: .sampleOneTime) { _ in }
        .frame(width: 320)
        .padding()
}

#Preview("Paused") {
    ReminderRowView(reminder: .samplePaused) { _ in }
        .frame(width: 320)
        .padding()
}
#endif
```

- [ ] **Step 2: Build to verify**

Run:
```bash
xcodebuild build -project Ripple.xcodeproj -scheme Ripple -configuration Debug -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Ripple/Views/ReminderRowView.swift
git commit -m "feat: add SwiftUI previews to ReminderRowView"
```

---

### Task 4: Add previews to ReminderDetailView

**Files:**
- Modify: `Ripple/Views/ReminderDetailView.swift`

- [ ] **Step 1: Add preview blocks at the bottom of the file**

Append the following to the end of `Ripple/Views/ReminderDetailView.swift`:

```swift
// MARK: - Previews

#if DEBUG
#Preview("Recurring Detail") {
    ReminderDetailView(reminder: .sampleRecurring)
        .environment(\.schedulerEngine, PreviewSchedulerEngine())
        .frame(width: 320)
}

#Preview("One-Time Detail") {
    ReminderDetailView(reminder: .sampleOneTime)
        .environment(\.schedulerEngine, PreviewSchedulerEngine())
        .frame(width: 320)
}

#Preview("Paused Detail") {
    ReminderDetailView(reminder: .samplePaused)
        .environment(\.schedulerEngine, PreviewSchedulerEngine())
        .frame(width: 320)
}
#endif
```

- [ ] **Step 2: Build to verify**

Run:
```bash
xcodebuild build -project Ripple.xcodeproj -scheme Ripple -configuration Debug -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Ripple/Views/ReminderDetailView.swift
git commit -m "feat: add SwiftUI previews to ReminderDetailView"
```

---

### Task 5: Add previews to ReminderFormView

**Files:**
- Modify: `Ripple/Views/ReminderFormView.swift`

`ReminderFormView` takes a `Binding<NavigationPath>`. For previews, use a `.constant(NavigationPath())` binding.

- [ ] **Step 1: Add preview blocks at the bottom of the file**

Append the following to the end of `Ripple/Views/ReminderFormView.swift`:

```swift
// MARK: - Previews

#if DEBUG
#Preview("Add New") {
    NavigationStack {
        ReminderFormView(path: .constant(NavigationPath()))
    }
    .environment(previewStore())
    .frame(width: 320)
}

#Preview("Edit Recurring") {
    NavigationStack {
        ReminderFormView(reminder: .sampleRecurring, path: .constant(NavigationPath()))
    }
    .environment(previewStore())
    .frame(width: 320)
}

#Preview("Edit One-Time") {
    NavigationStack {
        ReminderFormView(reminder: .sampleOneTime, path: .constant(NavigationPath()))
    }
    .environment(previewStore())
    .frame(width: 320)
}
#endif
```

- [ ] **Step 2: Build to verify**

Run:
```bash
xcodebuild build -project Ripple.xcodeproj -scheme Ripple -configuration Debug -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Ripple/Views/ReminderFormView.swift
git commit -m "feat: add SwiftUI previews to ReminderFormView"
```

---

### Task 6: Add previews to ReminderListView

**Files:**
- Modify: `Ripple/Views/ReminderListView.swift`

`ReminderListView` uses `SMAppService` (ServiceManagement) for launch-at-login. This works fine in previews — it just reads the current state.

- [ ] **Step 1: Add preview blocks at the bottom of the file**

Append the following to the end of `Ripple/Views/ReminderListView.swift`:

```swift
// MARK: - Previews

#if DEBUG
#Preview("With Reminders") {
    NavigationStack {
        ReminderListView()
    }
    .environment(previewStore())
    .frame(width: 320)
}

#Preview("Empty") {
    NavigationStack {
        ReminderListView()
    }
    .environment(previewStore(reminders: []))
    .frame(width: 320)
}

#Preview("Notifications Blocked") {
    NavigationStack {
        ReminderListView()
    }
    .environment(previewStoreBlocked())
    .frame(width: 320)
}
#endif
```

- [ ] **Step 2: Build to verify**

Run:
```bash
xcodebuild build -project Ripple.xcodeproj -scheme Ripple -configuration Debug -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Ripple/Views/ReminderListView.swift
git commit -m "feat: add SwiftUI previews to ReminderListView"
```

---

### Task 7: Add preview to ContentView

**Files:**
- Modify: `Ripple/ContentView.swift`

- [ ] **Step 1: Add preview block at the bottom of the file**

Append the following to the end of `Ripple/ContentView.swift`:

```swift
// MARK: - Previews

#if DEBUG
#Preview("Default") {
    ContentView()
        .environment(previewStore())
        .environment(\.schedulerEngine, PreviewSchedulerEngine())
}
#endif
```

Note: No explicit `.frame(width: 320)` needed here because `ContentView.body` already applies `.frame(width: 320)`.

- [ ] **Step 2: Build to verify**

Run:
```bash
xcodebuild build -project Ripple.xcodeproj -scheme Ripple -configuration Debug -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Run tests to make sure nothing is broken**

Run:
```bash
xcodebuild test -project Ripple.xcodeproj -scheme Ripple -configuration Debug -quiet 2>&1 | tail -10
```
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Ripple/ContentView.swift
git commit -m "feat: add SwiftUI preview to ContentView"
```
