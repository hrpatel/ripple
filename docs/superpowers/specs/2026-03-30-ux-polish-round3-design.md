# UX Polish Round 3 — Design Spec

## Overview

A set of targeted UX fixes and improvements across the main list view and add/edit form view in the Ripple menubar app.

## Main List View

### 1. Remove "Filter" label

Remove the `Text("Filter")` label and its padding above the segmented picker in `ReminderListView.swift`. The segmented picker (All / Active / Paused) is self-explanatory.

### 2. Dynamic resizing instead of scrolling

Replace the `List` with a `ForEach` inside a `ScrollView` that uses `.fixedSize(horizontal: false, vertical: true)`, capped by the existing `maxHeight: 600` on `ContentView`. The popover grows to fit content and only scrolls when it overflows. The empty state keeps its current centered layout.

### 3. Edit and delete icons on each reminder row

Update `ReminderRowView` layout to: `[toggle] [title/subtitle] [Spacer] [type badge] [pencil icon] [X icon]`.

- **Pencil icon**: `pencil` SF Symbol. Navigates directly to the edit form (skipping detail view).
- **X icon**: `xmark` SF Symbol. Shows a confirmation alert, then deletes the reminder.
- Both are small `.plain` button style so they don't interfere with the row's existing `NavigationLink` tap target to the detail view.
- The row itself still navigates to the detail view when tapped.

Callbacks needed: `onEdit` and `onDelete` closures passed into `ReminderRowView`.

### 4. Left-justify "Launch at login"

Replace the `Toggle` with an `HStack` containing:
- `Text("Launch at login")` left-aligned
- `Spacer()`
- A `checkmark` SF Symbol icon, visible only when enabled

The entire row is tappable to toggle the state. Gives a cleaner, left-aligned look matching the rest of the UI.

## Add/Edit Form View

### 5. Smoother resizing animations

Add `.animation(.easeInOut(duration: 0.3), value: type)` and `.animation(.easeInOut(duration: 0.3), value: activeHoursEnabled)` to the form content. This makes section swaps (recurring vs one-time) and active hours toggle animate smoothly instead of snapping.

### 6. Reminder title in edit view header

When editing, display the reminder's actual title in the header (e.g. "Stretch break") instead of the generic "Edit Reminder". When adding a new reminder, keep "Add Reminder".

### 7. Fix footer buttons being cut off

The current `Spacer()` between form content and footer pushes the footer to the bottom, but frame constraints clip it. Fix by:
- Removing the `Spacer()`
- Wrapping the form content in a `ScrollView` so it scrolls when content is tall
- Pinning the footer (`footerSection`) outside the scroll view at the bottom

This ensures delete/cancel/save buttons are always visible.

## Files Modified

- `Ripple/Views/ReminderListView.swift` — changes 1, 2, 3, 4
- `Ripple/Views/ReminderRowView.swift` — change 3
- `Ripple/Views/ReminderFormView.swift` — changes 5, 6, 7
- `Ripple/ContentView.swift` — possible frame adjustments for change 2
