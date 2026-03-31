# Changelog

## [1.0.1](https://github.com/hrpatel/ripple/compare/v1.0.0...v1.0.1) (2026-03-31)


### Bug Fixes

* prevent one-time reminders from being set in the past ([fe3b51a](https://github.com/hrpatel/ripple/commit/fe3b51add2ebc67282b9ce459f0f46b6792991c4))

## 1.0.0 (2026-03-31)

### Features

* add active hours, active days, and disabled checks to SchedulerEngine ([1856a11](https://github.com/hrpatel/ripple/commit/1856a11adf8aad16d419760f638800f7acc00d15))
* add app icon ([bea1f9a](https://github.com/hrpatel/ripple/commit/bea1f9a8130763c35f3e7554f8a1fc4ff16b568a))
* add configurable snooze duration and overnight active hours to SchedulerEngine ([9f1150f](https://github.com/hrpatel/ripple/commit/9f1150f6687460271403e950072984e4d8387108))
* add DeliveryManager with notification, sound, and menubar flash ([6ac965b](https://github.com/hrpatel/ripple/commit/6ac965b2b83df42b53213384c2073c98a2a11269))
* add divider after header and Filter section heading ([6838511](https://github.com/hrpatel/ripple/commit/6838511f676eadd1c66e0f844de3799984f71c93))
* add green dot icon, observation tracking, and flash restore to AppDelegate ([db1e7cb](https://github.com/hrpatel/ripple/commit/db1e7cb5032b570beee5798b1e454be5b781ab6e))
* add nextFireDate(for:) to SchedulerEngine ([10380ca](https://github.com/hrpatel/ripple/commit/10380ca88de49daafc43975bc000c8d02fc96cef))
* add notification blocked banner and launch-at-login toggle ([5f533e0](https://github.com/hrpatel/ripple/commit/5f533e027f7d60d4b8ba25e820d6c08ce25f23d5))
* add notificationsBlocked flag to ReminderStore ([befc902](https://github.com/hrpatel/ripple/commit/befc9020ebab4ebc3206f1b58f4c0bd7a5863bdc))
* add one-time reminder fire-and-disable to SchedulerEngine ([840884e](https://github.com/hrpatel/ripple/commit/840884e11ef1d0e4974b686d89a8ca6eaa233003))
* add onNotificationsBlocked callback and permission check to DeliveryManager ([5e8258f](https://github.com/hrpatel/ripple/commit/5e8258f3b8d1b14c1498b7291035d7451dd47da6))
* add PersistenceManager and ReminderStore with tests ([1bcde06](https://github.com/hrpatel/ripple/commit/1bcde065f7453335abd1113b6c2734c6d5dd2cad))
* add Reminder data model structs ([70d940f](https://github.com/hrpatel/ripple/commit/70d940f00442c75495aa1c273d2f4283ffb7f963))
* add Reminder display formatting helpers ([9f589cb](https://github.com/hrpatel/ripple/commit/9f589cb39c74c6d92f9a6576c6ec480f8e5fa6ed))
* add ReminderDetailView with info fields and delivery tags ([27cc790](https://github.com/hrpatel/ripple/commit/27cc790b4debe60e36439600447457adc1b7d991))
* add ReminderFormView for creating and editing reminders ([4ff54d9](https://github.com/hrpatel/ripple/commit/4ff54d90cb79174fc25c527a024a17d8fb869cec))
* add ReminderListView with tabs, filter, and empty states ([067cee2](https://github.com/hrpatel/ripple/commit/067cee2eb3256c6778744f72d05ed4b67e954a17))
* add ReminderRowView with toggle, title, subtitle, badge ([874ea6b](https://github.com/hrpatel/ripple/commit/874ea6b1b71e4150a504906338ee850519057ad1))
* add sample data and preview helpers for SwiftUI previews ([5b6bdcc](https://github.com/hrpatel/ripple/commit/5b6bdccf7a45127eb428295609e04a3a65baeec7))
* add SchedulerEngine scaffold and recurring interval logic ([0f4b53b](https://github.com/hrpatel/ripple/commit/0f4b53b25cbc06daecf86077dcbd458371f968fe))
* add snoozeLabel formatting helper ([ae4839a](https://github.com/hrpatel/ripple/commit/ae4839a043c5ba5fc33a5f1f710df81ab4732754))
* add SwiftUI previews to all views ([804904e](https://github.com/hrpatel/ripple/commit/804904ef42bc394e4ad237cd40c636eff6be15cd))
* add Weekday.letter for day pill toggles ([214aec4](https://github.com/hrpatel/ripple/commit/214aec4d46828bd7c3a71558ed19b3cb38c895b7))
* add Xcode project scaffold (Phase 1) ([d216538](https://github.com/hrpatel/ripple/commit/d216538cb5f06310af8a80f7eea58515b0e1ea91))
* app shell — menubar icon, popover, placeholder view ([6691447](https://github.com/hrpatel/ripple/commit/6691447bde21d165d1d684c9b1b6cf71ef8a524f))
* compact form layout to avoid scrolling, add implementation plan ([910cbb8](https://github.com/hrpatel/ripple/commit/910cbb89dee1e8d9ba519d72e14f7ab387d59484))
* default active hours on, top-justify form content ([ad1a905](https://github.com/hrpatel/ripple/commit/ad1a905490f451b533a915a7348872ccd6872cac))
* dynamic popover sizing via preferredContentSize ([51e54b5](https://github.com/hrpatel/ripple/commit/51e54b5716efc82e58fc3f0bbf7271cba5cf843e))
* inline title field, remove duplicate Type label ([f62e8f3](https://github.com/hrpatel/ripple/commit/f62e8f3e40ed44c4367e46e1e8cfd3966d00cdf2))
* replace snooze toggle with duration picker, allow overnight hour ranges ([28de8e3](https://github.com/hrpatel/ripple/commit/28de8e34ecfef5c7d257ab1e9069e0644a468ac1))
* replace snoozeEnabled with snoozeDurationMinutes on Reminder ([3a6c041](https://github.com/hrpatel/ripple/commit/3a6c04165ec03d10d922e5258fda433856b6362e))
* show snooze duration in reminder detail view ([eafe57e](https://github.com/hrpatel/ripple/commit/eafe57ebab8f30ed3e075bd7b1354aae50322f84))
* update ContentView with NavigationStack and SchedulerEngine environment ([85250c8](https://github.com/hrpatel/ripple/commit/85250c82f47a65a4d1fe79e99889e7e3c14800ea))
* update DeliveryManager with per-duration categories and flash restore callback ([aa365d9](https://github.com/hrpatel/ripple/commit/aa365d962ffa25f677f899e6782729b2267f2050))
* verify snooze logic in SchedulerEngine ([58291a1](https://github.com/hrpatel/ripple/commit/58291a17c133dbbf316aab73406192147d334aca))
* wire add/edit form into navigation with RippleDestination routing ([200bff1](https://github.com/hrpatel/ripple/commit/200bff1c364535daa93046c2280b902c193b288e))
* wire notificationsBlocked callback in AppDelegate ([ddacc1e](https://github.com/hrpatel/ripple/commit/ddacc1ebfc6dd9134f18f48f0dc0e85716377377))
* wire SchedulerEngine and DeliveryManager into AppDelegate ([7c505f8](https://github.com/hrpatel/ripple/commit/7c505f8a21db14a1853cfcd6482f8cecbd1489cf))
* wire SchedulerEngine environment and reorder AppDelegate setup ([4e4eda8](https://github.com/hrpatel/ripple/commit/4e4eda84e7313b234c7a8695b18e89d5b95f996a))


### Bug Fixes

* add back button to ReminderDetailView for popover navigation ([7d5aee2](https://github.com/hrpatel/ripple/commit/7d5aee232ba5c2c17e347707612925dcf3d95da5))
* ensure flash timer runs on main thread, make updateMenubarIcon private ([3ad5a68](https://github.com/hrpatel/ripple/commit/3ad5a682dd0997f4f1b293762b3bb5ea63131577))
* switch ReminderStore to @Observable, fix test_add_persistsReminder ([8429a72](https://github.com/hrpatel/ripple/commit/8429a72f0dd70f311f587cf2036389c838f26872))
* update test helpers for snoozeDurationMinutes model change ([6e44e7c](https://github.com/hrpatel/ripple/commit/6e44e7c443b52b0c0e1d0cdcfc91366d027f26a0))
* use Int for active hours (minutes since midnight), make activeDays optional, add isValid ([c394a02](https://github.com/hrpatel/ripple/commit/c394a02064c1cece6369ceacc8329418da8de7cd))
* use squareLength for status item, guard nil popover in togglePopover ([df5aa44](https://github.com/hrpatel/ripple/commit/df5aa44216b7731448404ad55891b69b4ec34f6b))


### Breaking

* Reminder JSON format changed (`snoozeEnabled` replaced by `snoozeDurationMinutes`) — existing saved reminders will be reset on first launch
