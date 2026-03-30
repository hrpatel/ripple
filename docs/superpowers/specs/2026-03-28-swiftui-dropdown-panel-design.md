# SwiftUI Dropdown Panel — Design Spec

> **Phase 2, Step 7** of the Ripple implementation plan.

## Goal

Replace the placeholder `ContentView` with a fully functional reminder list and detail view inside the menubar popover. Users can browse, filter, and toggle reminders. Tapping a row navigates to a detail view showing all reminder metadata and the next trigger time.

---

## Navigation Model

Single `NavigationStack` inside the popover. The list view is the root. Tapping a reminder row pushes to the detail view. A back button returns to the list.

Popover size is not hardcoded — let the content drive it.

---

## List View (Root)

### Header
- Left: **"Reminders"** title
- Right: **"+ Add"** button (non-functional — wired in Step 8)

### Tab Bar
Three tabs, in this order: **All / Active / Paused**
- **All** — every reminder (default selected tab)
- **Active** — reminders where `isEnabled == true`
- **Paused** — reminders where `isEnabled == false`

### Reminder Rows
Each row contains:
- **Toggle switch** (left) — directly controls `isEnabled` on the reminder via `ReminderStore.update()`
- **Title** — e.g. "Stand up"
- **Subtitle** — contextual summary:
  - Recurring: "Every 45 min \u00b7 9am\u20136pm" (interval + active hours if set; "all day" if no active hours)
  - One-time: "Today at 10:00 AM" or formatted date
- **Badge** (right) — "recurring" or "one-time", visually distinct

### Empty State
When the filtered list is empty, show centered text:
- All tab: "No reminders yet"
- Active tab: "No active reminders"
- Paused tab: "No paused reminders"

---

## Detail View (Pushed)

### Header
- **Title** — reminder title (large)
- **Subtitle** — "Recurring reminder" or "One-time reminder"

### Info Fields

For recurring reminders:
| Label | Value |
|-------|-------|
| INTERVAL | "Every 45 min" |
| ACTIVE HOURS | "9am \u2013 6pm" (or "All day" if nil) |
| DAYS | "Mon \u2013 Fri" (or "Every day" if nil) |
| NEXT TRIGGER | "10:15 AM" (calculated) or "Paused" if disabled |

For one-time reminders:
| Label | Value |
|-------|-------|
| SCHEDULED | Formatted date and time |
| STATUS | "Pending" if enabled, "Fired" if disabled |

### Next Trigger Calculation
Add a `nextFireDate(for:)` method to `SchedulerEngine`:
- **Recurring:** `lastFired[id] + intervalMinutes`. If never fired, next trigger is now (will fire on next tick). Does not account for active hours/days — returns the raw interval-based time.
- **One-time:** returns `scheduledDate` if still enabled, `nil` if already fired.
- **Paused:** returns `nil`.

### Delivery Tags
Row of pill-shaped tags: **Notification**, **Sound**, **Menubar Icon**
- Highlighted/filled when the delivery option is enabled
- Dimmed/outline when disabled

### Edit Button
"Edit reminder" button at the bottom — non-functional until Step 8.

---

## Files

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `Ripple/Views/ReminderListView.swift` | Tab bar, filtered list, header, empty states |
| Create | `Ripple/Views/ReminderRowView.swift` | Single row: toggle, title, subtitle, badge |
| Create | `Ripple/Views/ReminderDetailView.swift` | Detail view: info fields, delivery tags, edit button |
| Modify | `Ripple/ContentView.swift` | Replace placeholder with NavigationStack + ReminderListView |
| Modify | `Ripple/Scheduling/SchedulerEngine.swift` | Add `nextFireDate(for:)` method |
| Modify | `Ripple/AppDelegate.swift` | Pass `engine` into the SwiftUI environment so detail view can call `nextFireDate` |

---

## Constraints

- No new persistence or scheduling changes — this is purely UI + one read-only method on SchedulerEngine.
- "+ Add" and "Edit reminder" buttons are visible but non-functional (Step 8).
- `ReminderStore` is already `@Observable` and passed via `.environment()` — views observe it automatically.
- `SchedulerEngine` needs to be accessible from SwiftUI views for `nextFireDate`. Pass it via `.environment()` alongside the store.

---

## Out of Scope
- Add/Edit form (Step 8)
- Green dot on menubar icon for active reminders (Step 10 polish)
- Notification body text (Step 10 polish)
