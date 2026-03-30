import SwiftUI

struct ReminderFormView: View {
    let reminderToEdit: Reminder?
    @Binding var path: NavigationPath
    @Environment(ReminderStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var title: String
    @State private var type: ReminderType
    @State private var intervalSelection: Int
    @State private var customIntervalText: String
    @State private var activeHoursEnabled: Bool
    @State private var activeHoursStart: Int
    @State private var activeHoursEnd: Int
    @State private var activeDays: Set<Weekday>
    @State private var scheduledDate: Date
    @State private var notificationEnabled: Bool
    @State private var soundEnabled: Bool
    @State private var menubarFlashEnabled: Bool
    @State private var snoozeDurationMinutes: Int?

    private let intervalPresets = [15, 30, 45, 60, 90, 120]
    private let snoozePresets = [1, 5, 10, 15, 30]

    private var availableSnoozePresets: [Int] {
        guard type == .recurring, let interval = resolvedInterval else { return snoozePresets }
        return snoozePresets.filter { $0 < interval }
    }

    var isEditing: Bool { reminderToEdit != nil }

    init(reminder: Reminder? = nil, path: Binding<NavigationPath>) {
        self.reminderToEdit = reminder
        self._path = path

        _title = State(initialValue: reminder?.title ?? "")
        _type = State(initialValue: reminder?.type ?? .recurring)

        let interval = reminder?.intervalMinutes ?? 30
        if let idx = [15, 30, 45, 60, 90, 120].firstIndex(of: interval) {
            _intervalSelection = State(initialValue: idx)
            _customIntervalText = State(initialValue: "")
        } else {
            _intervalSelection = State(initialValue: -1)
            _customIntervalText = State(initialValue: "\(interval)")
        }

        _activeHoursEnabled = State(initialValue: reminder?.activeHoursStart != nil || reminder == nil)
        _activeHoursStart = State(initialValue: reminder?.activeHoursStart ?? 540)
        _activeHoursEnd = State(initialValue: reminder?.activeHoursEnd ?? 1020)
        _activeDays = State(initialValue: reminder?.activeDays ?? Set(Weekday.allCases))
        _scheduledDate = State(initialValue: reminder?.scheduledDate ?? Date().addingTimeInterval(3600))
        _notificationEnabled = State(initialValue: reminder?.delivery.notification ?? true)
        _soundEnabled = State(initialValue: reminder?.delivery.sound ?? false)
        _menubarFlashEnabled = State(initialValue: reminder?.delivery.menubarIconFlash ?? false)
        _snoozeDurationMinutes = State(initialValue: reminder?.snoozeDurationMinutes)
    }

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
                Text(isEditing ? "Edit Reminder" : "Add Reminder")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 6)

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

            Spacer()

            Divider()
            footerSection
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        HStack {
            Text("Title")
                .font(.subheadline)
                .fontWeight(.medium)
            TextField("Reminder title", text: $title)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Type

    private var typeSection: some View {
        Picker("Type", selection: $type) {
            Text("Recurring").tag(ReminderType.recurring)
            Text("One-time").tag(ReminderType.oneTime)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Recurring fields

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Interval
            HStack {
                Text("Interval")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("Interval", selection: $intervalSelection) {
                    ForEach(0..<intervalPresets.count, id: \.self) { idx in
                        Text(intervalPresets[idx] >= 60
                            ? "\(intervalPresets[idx] / 60) hr"
                            : "\(intervalPresets[idx]) min"
                        ).tag(idx)
                    }
                    Text("Custom").tag(-1)
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            if intervalSelection == -1 {
                HStack {
                    TextField("Minutes", text: $customIntervalText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("minutes")
                        .foregroundStyle(.secondary)
                }
            }

            // Active hours
            Toggle("Active hours", isOn: $activeHoursEnabled)

            if activeHoursEnabled {
                HStack {
                    Picker("Start", selection: $activeHoursStart) {
                        ForEach(timeOptions, id: \.self) { minutes in
                            Text(formatTime(minutes)).tag(minutes)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 110)

                    Text("to")
                        .foregroundStyle(.secondary)

                    Picker("End", selection: $activeHoursEnd) {
                        ForEach(timeOptions, id: \.self) { minutes in
                            Text(formatTime(minutes)).tag(minutes)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 110)
                }
            }

            // Active days
            Text("Active days")
                .font(.subheadline)
                .fontWeight(.medium)
            HStack(spacing: 6) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Button(action: { toggleDay(day) }) {
                        Text(day.letter)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle().fill(activeDays.contains(day)
                                    ? Color.blue
                                    : Color.clear)
                            )
                            .foregroundStyle(activeDays.contains(day) ? .white : .primary)
                            .overlay(Circle().stroke(Color.gray.opacity(0.3)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - One-time fields

    private var oneTimeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Date & Time")
                .font(.subheadline)
                .fontWeight(.medium)
            DatePicker("", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
        }
    }

    // MARK: - Delivery

    private var deliverySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Delivery")
                .font(.subheadline)
                .fontWeight(.medium)
            Toggle("Notification", isOn: $notificationEnabled)
                .controlSize(.small)
            Toggle("Sound", isOn: $soundEnabled)
                .controlSize(.small)
            Toggle("Menubar icon flash", isOn: $menubarFlashEnabled)
                .controlSize(.small)
        }
    }

    // MARK: - Snooze

    private var snoozeSection: some View {
        HStack {
            Text("Snooze")
                .font(.subheadline)
                .fontWeight(.medium)

            Picker("Snooze", selection: $snoozeDurationMinutes) {
                Text("Off").tag(Int?.none)
                ForEach(availableSnoozePresets, id: \.self) { mins in
                    Text("\(mins) min").tag(Int?.some(mins))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .onChange(of: resolvedInterval) { _, newInterval in
            if let snooze = snoozeDurationMinutes,
               let interval = newInterval,
               snooze >= interval {
                snoozeDurationMinutes = nil
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            if isEditing {
                Button("Delete") { deleteReminder() }
                    .foregroundStyle(.red)
                    .buttonStyle(.plain)
            }

            Spacer()

            Button("Cancel") { dismiss() }
                .buttonStyle(.plain)

            Button(isEditing ? "Save" : "Add Reminder") { save() }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
        }
        .padding()
    }

    // MARK: - Computed

    private var resolvedInterval: Int? {
        if intervalSelection >= 0 && intervalSelection < intervalPresets.count {
            return intervalPresets[intervalSelection]
        }
        return Int(customIntervalText)
    }

    private var isValid: Bool {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        switch type {
        case .recurring:
            guard let mins = resolvedInterval, mins > 0 else { return false }
            if activeHoursEnabled && activeHoursStart == activeHoursEnd { return false }
            return true
        case .oneTime:
            return true
        }
    }

    private var timeOptions: [Int] {
        Array(stride(from: 0, through: 1410, by: 30))
    }

    // MARK: - Actions

    private func save() {
        let finalDays: Set<Weekday>? = (activeDays.count == 7 || activeDays.isEmpty) ? nil : activeDays

        let reminder = Reminder(
            id: reminderToEdit?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            type: type,
            intervalMinutes: type == .recurring ? resolvedInterval : nil,
            scheduledDate: type == .oneTime ? scheduledDate : nil,
            activeHoursStart: (type == .recurring && activeHoursEnabled) ? activeHoursStart : nil,
            activeHoursEnd: (type == .recurring && activeHoursEnabled) ? activeHoursEnd : nil,
            activeDays: type == .recurring ? finalDays : nil,
            isEnabled: reminderToEdit?.isEnabled ?? true,
            delivery: DeliveryOptions(
                notification: notificationEnabled,
                sound: soundEnabled,
                menubarIconFlash: menubarFlashEnabled
            ),
            snoozeDurationMinutes: snoozeDurationMinutes
        )

        if isEditing {
            store.update(reminder)
        } else {
            store.add(reminder)
        }

        path = NavigationPath()
    }

    private func deleteReminder() {
        if let reminder = reminderToEdit {
            store.delete(reminder)
        }
        path = NavigationPath()
    }

    private func toggleDay(_ day: Weekday) {
        if activeDays.contains(day) {
            activeDays.remove(day)
        } else {
            activeDays.insert(day)
        }
    }

    private func formatTime(_ totalMinutes: Int) -> String {
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        let period = h < 12 ? "AM" : "PM"
        let displayH: Int
        if h == 0 { displayH = 12 }
        else if h > 12 { displayH = h - 12 }
        else { displayH = h }
        return String(format: "%d:%02d %@", displayH, m, period)
    }
}
