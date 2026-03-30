import SwiftUI
import ServiceManagement

enum ReminderFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case paused = "Paused"
}

struct ReminderListView: View {
    @Environment(ReminderStore.self) var store
    @State private var selectedFilter: ReminderFilter = .all
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var filteredReminders: [Reminder] {
        switch selectedFilter {
        case .all: return store.reminders
        case .active: return store.reminders.filter { $0.isEnabled }
        case .paused: return store.reminders.filter { !$0.isEnabled }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Notification blocked banner
            if store.notificationsBlocked {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Notifications are blocked — reminders won't appear.")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button("Open System Settings") {
                        NSWorkspace.shared.open(
                            URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
                        )
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(.yellow.opacity(0.15))
            }

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

            // List or empty state
            if filteredReminders.isEmpty {
                Spacer()
                Text(emptyMessage)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                Spacer()
            } else {
                List(filteredReminders) { reminder in
                    NavigationLink(value: RippleDestination.detail(reminder.id)) {
                        ReminderRowView(reminder: reminder) { newValue in
                            var updated = reminder
                            updated.isEnabled = newValue
                            store.update(updated)
                        }
                    }
                }
                .listStyle(.plain)
            }

            Divider()
            Toggle("Launch at login", isOn: $launchAtLogin)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .onChange(of: launchAtLogin) { _, newValue in
                    if newValue {
                        try? SMAppService.mainApp.register()
                    } else {
                        try? SMAppService.mainApp.unregister()
                    }
                }
                .onAppear {
                    launchAtLogin = SMAppService.mainApp.status == .enabled
                }
        }
    }

    private var emptyMessage: String {
        switch selectedFilter {
        case .all: return "No reminders yet"
        case .active: return "No active reminders"
        case .paused: return "No paused reminders"
        }
    }
}
