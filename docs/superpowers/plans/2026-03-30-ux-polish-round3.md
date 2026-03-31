# UX Polish Round 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 7 UX issues across the main list view and add/edit form view in the Ripple menubar app.

**Architecture:** All changes are view-layer only. Four SwiftUI files are modified: `ReminderListView` (filter label, dynamic sizing, launch-at-login, row wiring), `ReminderRowView` (edit/delete icons), `ReminderFormView` (animation, header title, scroll layout), and `ContentView` (frame adjustment).

**Tech Stack:** SwiftUI, macOS 14+, ServiceManagement

---

### Task 1: Remove "Filter" label from main list

**Files:**
- Modify: `Ripple/Views/ReminderListView.swift:65-70`

- [ ] **Step 1: Remove the Filter label**

Delete lines 65-70 (the `Text("Filter")` and its modifiers). Add `.padding(.top, 8)` to the Picker to preserve spacing:

```swift
            Picker("Filter", selection: $selectedFilter) {
                ForEach(ReminderFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
```

- [ ] **Step 2: Build and verify**

Run: `cmd+B` in Xcode or `xcodebuild build` — confirm no compile errors. Open the popover and verify the "Filter" text is gone and the segmented picker has appropriate spacing below the divider.

- [ ] **Step 3: Commit**

```bash
git add Ripple/Views/ReminderListView.swift
git commit -m "fix: remove Filter label from main list view"
```

---

### Task 2: Dynamic resizing instead of scrolling list

**Files:**
- Modify: `Ripple/Views/ReminderListView.swift:82-100`
- Modify: `Ripple/ContentView.swift:47-48`

- [ ] **Step 1: Replace List with ScrollView + ForEach in ReminderListView**

Replace lines 82-100 (the `if filteredReminders.isEmpty ... else ... List ...` block) with:

```swift
            if filteredReminders.isEmpty {
                Spacer()
                Text(emptyMessage)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredReminders) { reminder in
                            NavigationLink(value: RippleDestination.detail(reminder.id)) {
                                ReminderRowView(reminder: reminder, onToggle: { newValue in
                                    var updated = reminder
                                    updated.isEnabled = newValue
                                    store.update(updated)
                                })
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
```

- [ ] **Step 2: Adjust ContentView frame**

In `ContentView.swift`, change the frame to allow the popover to shrink smaller for fewer items. Replace lines 47-48:

```swift
        .frame(width: 320)
        .frame(maxHeight: 600)
```

Remove the `minHeight: 200` so the popover can shrink to fit content dynamically.

- [ ] **Step 3: Build and verify**

Build the project. Open the popover — with 0 reminders it should show the empty state without excess whitespace. With 1-2 reminders it should size to fit. With many reminders it should scroll at 600px max height.

- [ ] **Step 4: Commit**

```bash
git add Ripple/Views/ReminderListView.swift Ripple/ContentView.swift
git commit -m "fix: dynamic popover resizing instead of fixed scrolling list"
```

---

### Task 3: Add edit (pencil) and delete (x) icons to reminder rows

**Files:**
- Modify: `Ripple/Views/ReminderRowView.swift` (full file)
- Modify: `Ripple/Views/ReminderListView.swift:90-98` (wiring callbacks)

- [ ] **Step 1: Update ReminderRowView to accept onEdit and onDelete callbacks and add icons**

Replace the full `ReminderRowView` body with:

```swift
import SwiftUI

struct ReminderRowView: View {
    let reminder: Reminder
    let onToggle: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

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

            Button(action: { onEdit() }) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Button(action: { showDeleteConfirmation = true }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .alert("Delete Reminder", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(reminder.title)\"?")
        }
    }
}
```

- [ ] **Step 2: Update ReminderListView to pass onEdit and onDelete**

In `ReminderListView.swift`, update the `ForEach` block (from Task 2) to pass the new callbacks. The `NavigationLink` wrapping the row handles detail navigation. The `onEdit` callback navigates to the form, and `onDelete` deletes via the store. Replace the `ForEach` inside the `ScrollView`:

```swift
                        ForEach(filteredReminders) { reminder in
                            NavigationLink(value: RippleDestination.detail(reminder.id)) {
                                ReminderRowView(
                                    reminder: reminder,
                                    onToggle: { newValue in
                                        var updated = reminder
                                        updated.isEnabled = newValue
                                        store.update(updated)
                                    },
                                    onEdit: {},
                                    onDelete: {
                                        store.delete(reminder)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
```

Note: `onEdit` is empty for now because navigating from inside a `NavigationLink` requires access to the `NavigationPath`. We'll wire that up in the next step.

- [ ] **Step 3: Wire up onEdit navigation**

`ReminderListView` doesn't currently have access to the `NavigationPath`. We need to pass it down from `ContentView`.

In `ContentView.swift`, pass the path binding to `ReminderListView`:

```swift
            ReminderListView(path: $path)
```

In `ReminderListView.swift`, add a `path` binding property:

```swift
struct ReminderListView: View {
    @Environment(ReminderStore.self) var store
    @Binding var path: NavigationPath
    @State private var selectedFilter: ReminderFilter = .all
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
```

Then update `onEdit` in the `ForEach` to navigate:

```swift
                                    onEdit: {
                                        path.append(RippleDestination.form(reminder.id))
                                    },
```

- [ ] **Step 4: Build and verify**

Build the project. Open the popover with at least one reminder:
- Tap the pencil icon — should navigate directly to the edit form.
- Tap the X icon — should show "Delete Reminder" confirmation alert. Confirm deletes; cancel dismisses.
- Tap the row body — should still navigate to the detail view.

- [ ] **Step 5: Commit**

```bash
git add Ripple/Views/ReminderRowView.swift Ripple/Views/ReminderListView.swift Ripple/ContentView.swift
git commit -m "feat: add edit and delete icons to reminder rows"
```

---

### Task 4: Left-justify "Launch at login" with check icon

**Files:**
- Modify: `Ripple/Views/ReminderListView.swift:102-115`

- [ ] **Step 1: Replace the Toggle with a tappable HStack**

Replace lines 102-115 (the `Divider()`, `Toggle`, `.onChange`, `.onAppear` block) with:

```swift
            Divider()
            HStack {
                Text("Launch at login")
                Spacer()
                if launchAtLogin {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                launchAtLogin.toggle()
                if launchAtLogin {
                    try? SMAppService.mainApp.register()
                } else {
                    try? SMAppService.mainApp.unregister()
                }
            }
            .onAppear {
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
```

- [ ] **Step 2: Build and verify**

Build. Open the popover:
- "Launch at login" should be left-aligned with a blue checkmark on the right when enabled.
- When disabled, no icon on the right.
- Tapping the row toggles the state and the checkmark appears/disappears.

- [ ] **Step 3: Commit**

```bash
git add Ripple/Views/ReminderListView.swift
git commit -m "fix: left-justify launch at login with check icon"
```

---

### Task 5: Fix form view — smooth animations, edit title in header, pinned footer

This task addresses three spec items that all touch the `body` property in `ReminderFormView.swift`:
- Smoother resizing animations (spec item 5)
- Reminder title in edit view header (spec item 6)
- Footer buttons cut off (spec item 7)

**Files:**
- Modify: `Ripple/Views/ReminderFormView.swift:60-99`

- [ ] **Step 1: Replace the entire body property**

Replace the `body` computed property (lines 60-99) with:

```swift
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
                Text(isEditing ? (reminderToEdit?.title ?? "Edit Reminder") : "Add Reminder")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 6)

            ScrollView {
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
                .animation(.easeInOut(duration: 0.3), value: type)
                .animation(.easeInOut(duration: 0.3), value: activeHoursEnabled)
            }

            Divider()
            footerSection
        }
    }
```

Three changes from the original:
1. **Header title**: `"Edit Reminder"` → `reminderToEdit?.title ?? "Edit Reminder"` — shows the reminder's name when editing.
2. **ScrollView wrap**: Form fields are inside a `ScrollView`. The `Spacer()` is removed. `Divider()` and `footerSection` sit outside the scroll, pinned at the bottom — buttons are always visible.
3. **Animation**: `.animation(.easeInOut(duration: 0.3), value: type)` and `.animation(.easeInOut(duration: 0.3), value: activeHoursEnabled)` on the inner VStack — recurring/one-time swaps and active hours toggle animate smoothly.

- [ ] **Step 2: Build and verify**

Build. Test all three changes:
- **Footer**: Open the add/edit form — Delete, Cancel, and Save buttons should always be visible at the bottom, never clipped.
- **Scroll**: With recurring type (tallest form), scroll the form content — footer stays pinned.
- **Animation**: Toggle between Recurring and One-time — section swap should animate smoothly over 0.3s. Toggle "Active hours" on/off — time pickers slide in/out smoothly.
- **Header**: Edit an existing reminder — header should show the reminder's name. Add a new reminder — header should show "Add Reminder".

- [ ] **Step 3: Commit**

```bash
git add Ripple/Views/ReminderFormView.swift
git commit -m "fix: smooth animations, edit title in header, pinned footer in form view"
```
