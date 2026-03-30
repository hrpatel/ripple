# UX Polish Round 2 — Design Spec

**Date:** 2026-03-30
**Scope:** Layout and sizing refinements across the main list view and add/edit form view.

---

## 1. Dynamic Popover Sizing

**Problem:** The popover is fixed at 320x400 (`AppDelegate.setupPopover`), causing excess whitespace when content is short and no room to grow when content is tall.

**Change:**
- `AppDelegate.setupPopover`: Remove the fixed `contentSize`. Set `sizingOptions = .preferredContentSize` on the `NSHostingController` so the popover height is driven by the SwiftUI content's intrinsic size.
- `ContentView`: Replace `.frame(minWidth: 320, minHeight: 480)` with `.frame(width: 320)` plus `.frame(minHeight: 200, maxHeight: 600)` as safety bounds.

**Files:** `AppDelegate.swift`, `ContentView.swift`

---

## 2. Main View — Divider After Header

**Problem:** No visual separation between the "Reminders" header and the filter section below it.

**Change:** Add a `Divider()` in `ReminderListView` between the header HStack and the filter picker.

**File:** `ReminderListView.swift`

---

## 3. Main View — "Filter" as a Section Heading

**Problem:** "Filter" is only used as the picker's accessibility label and not visible to the user. The segmented control appears without context.

**Change:** Add `Text("Filter").font(.subheadline).fontWeight(.medium)` with horizontal padding above the segmented picker, matching the heading style used throughout the form view.

**File:** `ReminderListView.swift`

---

## 4. Form — Title Inline With Field

**Problem:** The "Title" label sits above the text field in a VStack, wasting vertical space.

**Change:** Change `titleSection` from a VStack to an HStack, placing the label inline to the left of the text field. This matches the layout pattern used by Interval and Snooze sections.

**File:** `ReminderFormView.swift` (`titleSection`)

---

## 5. Form — Remove Duplicate "Type" Label

**Problem:** "Type" appears twice — once as a section heading (`Text("Type")`) and once as the Picker's built-in label (`Picker("Type", ...)`).

**Change:** Remove the VStack wrapper and the `Text("Type")` heading from `typeSection`. Keep only the `Picker("Type", selection: $type)` with `.pickerStyle(.segmented)` — its built-in label renders inline to the left of the segments on macOS.

**File:** `ReminderFormView.swift` (`typeSection`)

---

## 6. Form — Default Active Hours Enabled

**Problem:** New reminders default to active hours disabled. Most users want daytime-only reminders.

**Change:** In `ReminderFormView.init`, when `reminder` is nil (new reminder), set `activeHoursEnabled` to `true` instead of `false`. The start (9:00 AM / 540) and end (5:00 PM / 1020) defaults are already correct.

**File:** `ReminderFormView.swift` (`init`)

---

## 7. Form — Top-Justified Content

**Problem:** When the popover is taller than the form content (e.g., one-time type with fewer fields), the content may not stay pinned to the top, causing it to shift when switching between recurring and one-time types.

**Change:** Add a `Spacer()` between the form content VStack and the `Divider()` + footer in the form's outer `VStack(spacing: 0)`. This pushes the footer to the bottom and keeps form fields anchored at the top regardless of content height.

**File:** `ReminderFormView.swift` (`body`)
