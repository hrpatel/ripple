# Changelog

All notable changes to Ripple are documented here.

## Unreleased

### Added
- Green dot on menubar icon when any reminder is active
- Configurable per-reminder snooze duration (1, 5, 10, 15, or 30 minutes)
- Overnight active hour ranges (e.g. 10pm–6am)
- Divider line between header and filter section in main view
- Edit (pencil) and delete (X) icons on each reminder row with delete confirmation
- Smooth animations when switching between recurring/one-time and toggling active hours

### Changed
- Snooze is now a duration picker instead of an on/off toggle
- Active hours no longer require start time to be before end time
- Popover dynamically resizes to fit content instead of fixed scrolling list
- "Title" label is now inline with the text field in the add/edit form
- Removed duplicate "Type" heading — single inline label remains
- Active hours default to enabled (9am–5pm) for new reminders
- Form content is top-justified so it doesn't shift when switching reminder types
- Removed redundant "Filter" label from main list — segmented picker is self-explanatory
- "Launch at login" is now left-justified with a checkmark icon instead of a checkbox toggle
- Edit view header shows the reminder's actual title instead of generic "Edit Reminder"
- Form footer (Delete/Cancel/Save) is pinned at the bottom and no longer gets cut off

### Breaking
- Reminder JSON format changed (`snoozeEnabled` replaced by `snoozeDurationMinutes`) — existing saved reminders will be reset on first launch
