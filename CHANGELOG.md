# Changelog

All notable changes to Ripple are documented here.

## Unreleased

### Added
- Green dot on menubar icon when any reminder is active
- Configurable per-reminder snooze duration (1, 5, 10, 15, or 30 minutes)
- Overnight active hour ranges (e.g. 10pm–6am)

### Changed
- Snooze is now a duration picker instead of an on/off toggle
- Active hours no longer require start time to be before end time

### Breaking
- Reminder JSON format changed (`snoozeEnabled` replaced by `snoozeDurationMinutes`) — existing saved reminders will be reset on first launch
