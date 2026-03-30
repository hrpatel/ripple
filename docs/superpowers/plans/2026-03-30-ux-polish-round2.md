# UX Polish Round 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine layout and sizing across the main list view and add/edit form so the popover is dynamic, content is top-justified, and labels/headings are consistent.

**Architecture:** All changes are SwiftUI layout modifications across four files. The popover switches from a fixed 320x400 size to intrinsic content sizing via `NSHostingController.sizingOptions`. View-level changes are divider/heading additions and HStack/VStack swaps.

**Tech Stack:** SwiftUI, AppKit (NSPopover, NSHostingController)

---

### Task 1: Dynamic Popover Sizing

**Files:**
- Modify: `Ripple/AppDelegate.swift:28-37` (setupPopover)
- Modify: `Ripple/ContentView.swift:29-48` (body)

- [ ] **Step 1: Update AppDelegate to use intrinsic sizing**

In `setupPopover`, remove the fixed `contentSize` and set `sizingOptions` on the hosting controller. Replace:

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

With:

```swift
private func setupPopover() {
    popover = NSPopover()
    popover.behavior = .transient
    let hostingController = NSHostingController(
        rootView: ContentView()
            .environment(store)
            .environment(\.schedulerEngine, engine)
    )
    hostingController.sizingOptions = .preferredContentSize
    popover.contentViewController = hostingController
}
```

Key changes:
- Removed `popover.contentSize = NSSize(width: 320, height: 400)`
- Extracted hosting controller to a local variable
- Added `hostingController.sizingOptions = .preferredContentSize`

- [ ] **Step 2: Update ContentView frame constraints**

In `ContentView`, replace the frame modifier. Change:

```swift
.frame(minWidth: 320, minHeight: 480)
```

To:

```swift
.frame(width: 320)
.frame(minHeight: 200, maxHeight: 600)
```

This fixes the width at 320 but lets height be driven by content, clamped between 200 and 600.

- [ ] **Step 3: Build and verify**

Run: `cd /Users/hpatel/Revisions/ripple/.claude/worktrees/zen-chebyshev && xcodebuild -scheme Ripple -configuration Debug build 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Ripple/AppDelegate.swift Ripple/ContentView.swift
git commit -m "feat: dynamic popover sizing via preferredContentSize"
```

---

### Task 2: Main View — Divider After Header and Filter Heading

**Files:**
- Modify: `Ripple/Views/ReminderListView.swift:48-71` (header and filter sections)

- [ ] **Step 1: Add divider after header and Filter heading**

In `ReminderListView`, find the header and tab bar sections (lines 48–71). Replace:

```swift
// Header
HStack {
    Text("Reminders")
        .font(.headline)
    Spacer()
    NavigationLink(value: RippleDestination.form(nil)) {
        Text("+ Add")
    }
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
```

With:

```swift
// Header
HStack {
    Text("Reminders")
        .font(.headline)
    Spacer()
    NavigationLink(value: RippleDestination.form(nil)) {
        Text("+ Add")
    }
    .buttonStyle(.plain)
    .foregroundStyle(.blue)
}
.padding(.horizontal)
.padding(.top, 12)
.padding(.bottom, 8)

Divider()

// Filter
Text("Filter")
    .font(.subheadline)
    .fontWeight(.medium)
    .padding(.horizontal)
    .padding(.top, 8)

Picker("Filter", selection: $selectedFilter) {
    ForEach(ReminderFilter.allCases, id: \.self) { filter in
        Text(filter.rawValue).tag(filter)
    }
}
.pickerStyle(.segmented)
.labelsHidden()
.padding(.horizontal)
.padding(.bottom, 8)
```

Key changes:
- Added `Divider()` after the header
- Added `Text("Filter")` heading with `.subheadline` + `.fontWeight(.medium)` matching the form's section heading style
- Added `.labelsHidden()` on the Picker since the heading now serves as the visible label

- [ ] **Step 2: Build and verify**

Run: `cd /Users/hpatel/Revisions/ripple/.claude/worktrees/zen-chebyshev && xcodebuild -scheme Ripple -configuration Debug build 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Ripple/Views/ReminderListView.swift
git commit -m "feat: add divider after header and Filter section heading"
```

---

### Task 3: Form — Title Inline and Type Dedup

**Files:**
- Modify: `Ripple/Views/ReminderFormView.swift:102-125` (titleSection, typeSection)

- [ ] **Step 1: Make Title inline with field**

In `ReminderFormView`, replace `titleSection`:

```swift
private var titleSection: some View {
    VStack(alignment: .leading, spacing: 4) {
        Text("Title")
            .font(.subheadline)
            .fontWeight(.medium)
        TextField("Reminder title", text: $title)
            .textFieldStyle(.roundedBorder)
    }
}
```

With:

```swift
private var titleSection: some View {
    HStack {
        Text("Title")
            .font(.subheadline)
            .fontWeight(.medium)
        TextField("Reminder title", text: $title)
            .textFieldStyle(.roundedBorder)
    }
}
```

- [ ] **Step 2: Remove duplicate Type label**

Replace `typeSection`:

```swift
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
```

With:

```swift
private var typeSection: some View {
    Picker("Type", selection: $type) {
        Text("Recurring").tag(ReminderType.recurring)
        Text("One-time").tag(ReminderType.oneTime)
    }
    .pickerStyle(.segmented)
}
```

The Picker's built-in "Type" label renders inline to the left of the segments on macOS.

- [ ] **Step 3: Build and verify**

Run: `cd /Users/hpatel/Revisions/ripple/.claude/worktrees/zen-chebyshev && xcodebuild -scheme Ripple -configuration Debug build 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Ripple/Views/ReminderFormView.swift
git commit -m "feat: inline title field, remove duplicate Type label"
```

---

### Task 4: Form — Default Active Hours and Top-Justify

**Files:**
- Modify: `Ripple/Views/ReminderFormView.swift:49` (init)
- Modify: `Ripple/Views/ReminderFormView.swift:60-98` (body)

- [ ] **Step 1: Default active hours enabled for new reminders**

In `ReminderFormView.init`, find line 49:

```swift
_activeHoursEnabled = State(initialValue: reminder?.activeHoursStart != nil)
```

Replace with:

```swift
_activeHoursEnabled = State(initialValue: reminder?.activeHoursStart != nil || reminder == nil)
```

This evaluates to `true` when creating a new reminder (reminder is nil) and preserves the existing behavior for editing (enabled only if the reminder already had active hours set). The start/end defaults of 540 (9 AM) and 1020 (5 PM) are already correct.

- [ ] **Step 2: Add Spacer for top-justified content**

In `ReminderFormView.body`, add a `Spacer()` between the form content and the divider/footer. Replace:

```swift
        .padding(.horizontal)
        .padding(.bottom, 8)

        Divider()
        footerSection
```

With:

```swift
        .padding(.horizontal)
        .padding(.bottom, 8)

        Spacer()

        Divider()
        footerSection
```

This pushes the footer to the bottom of the popover and keeps form fields anchored at the top, so switching between recurring/one-time doesn't shift content downward.

- [ ] **Step 3: Build and verify**

Run: `cd /Users/hpatel/Revisions/ripple/.claude/worktrees/zen-chebyshev && xcodebuild -scheme Ripple -configuration Debug build 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Ripple/Views/ReminderFormView.swift
git commit -m "feat: default active hours on, top-justify form content"
```
