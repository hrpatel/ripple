# Add/Edit Reminder Form — Design Spec

> **Phase 2, Step 8** of the Ripple implementation plan.

## Goal

Add a form view that lets users create new reminders and edit existing ones. The form pushes onto the NavigationStack inside the popover, consistent with the existing list → detail navigation pattern.

---

## Navigation

The form pushes onto the existing `NavigationStack` in `ContentView`:
- **"+ Add" button** (in ReminderListView header) → pushes form in add mode
- **"Edit reminder" button** (in ReminderDetailView) → pushes form in edit mode
- **Cancel** → pops back to previous view
- **Save/Add** → saves, then pops back to list
- **Delete** → deletes, then pops back to list

---

## Form Modes

### Add Mode
- Header: "Add Reminder"
- All fields start empty/default
- Footer: Cancel | "Add Reminder" (disabled until valid)

### Edit Mode
- Header: "Edit Reminder"
- Fields pre-populated from the existing reminder
- Footer: Delete | Cancel | Save (disabled until valid)

---

## Fields (top to bottom)

### 1. Title
- Text field
- Placeholder: "Reminder title"

### 2. Type
- Segmented picker: **Recurring** / **One-time**
- Switching type shows/hides the relevant fields below

### 3. Recurring-only fields

**Interval:**
- Picker with presets: 15 min, 30 min, 45 min, 60 min, 90 min, 2 hr
- Plus a "Custom" option that reveals a text field for entering a custom number of minutes
- Default: 30 min

**Active hours:**
- Toggle to enable/disable (off = all day, i.e. `activeHoursStart/End = nil`)
- When enabled: two dropdown menus for start and end time
- Dropdowns show 30-minute increments: 12:00 AM, 12:30 AM, 1:00 AM, ... 11:30 PM
- Values stored as minutes-since-midnight (e.g. 540 = 9:00 AM)
- Default start: 9:00 AM (540), default end: 5:00 PM (1020)

**Active days:**
- Row of 7 circular pill toggles: M T W T F S S
- Tappable — filled when selected, outline when not
- If all 7 selected or none selected → stored as `activeDays = nil` (every day)
- Default: all selected

### 4. One-time-only fields

**Date & time:**
- Standard macOS `DatePicker` with date and time components
- Default: 1 hour from now

### 5. Delivery toggles
- Three toggle switches, each labeled:
  - Notification (default: on)
  - Sound (default: off)
  - Menubar icon flash (default: off)

### 6. Snooze toggle
- Single toggle: "Snooze (5 min)" (default: off)

---

## Validation

The "Add Reminder" / "Save" button is disabled unless:
- Title is non-empty (after trimming whitespace)
- For recurring: interval is set and > 0
- For one-time: date is set
- If active hours enabled: start < end

---

## Data Flow

**Add mode:**
1. User fills fields
2. Taps "Add Reminder"
3. Form constructs a new `Reminder` with `UUID()` and `isEnabled = true`
4. Calls `store.add(reminder)`
5. Navigation pops back to list

**Edit mode:**
1. Form receives the existing `Reminder`
2. User modifies fields (local `@State` copy)
3. Taps "Save" → calls `store.update(reminder)` → pops to list
4. Taps "Delete" → calls `store.delete(reminder)` → pops to list
5. Taps "Cancel" → pops without saving

---

## Files

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `Ripple/Views/ReminderFormView.swift` | Full add/edit form |
| Modify | `Ripple/Views/ReminderListView.swift` | Wire "+ Add" button to push form |
| Modify | `Ripple/Views/ReminderDetailView.swift` | Wire "Edit reminder" button to push form |
| Modify | `Ripple/ContentView.swift` | Add `navigationDestination` for the form |

---

## Constraints

- No new model changes — the existing `Reminder` struct has all the fields needed.
- No scheduling changes — `SchedulerEngine` picks up new/edited reminders automatically on the next tick.
- Active hours dropdowns use 30-minute increments. Custom granularity is not supported.
- Active days uses `nil` to mean "every day" (same as all 7 selected or none selected).

---

## Out of Scope
- Reordering reminders
- Duplicate/clone reminder
- Undo after delete
