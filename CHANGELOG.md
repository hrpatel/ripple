# Changelog

All notable changes to Ripple are documented here.

## Unreleased

### Added
- Green dot on menubar icon when any reminder is active
- Configurable per-reminder snooze duration (1, 5, 10, 15, or 30 minutes)
- Overnight active hour ranges (e.g. 10pm–6am)
- Divider line between header and filter section in main view
- "Filter" section heading above the segmented picker

### Changed
- Snooze is now a duration picker instead of an on/off toggle
- Active hours no longer require start time to be before end time
- Popover dynamically resizes to fit content instead of fixed 320x400
- "Title" label is now inline with the text field in the add/edit form
- Removed duplicate "Type" heading — single inline label remains
- Active hours default to enabled (9am–5pm) for new reminders
- Form content is top-justified so it doesn't shift when switching reminder types

### Breaking
- Reminder JSON format changed (`snoozeEnabled` replaced by `snoozeDurationMinutes`) — existing saved reminders will be reset on first launch
