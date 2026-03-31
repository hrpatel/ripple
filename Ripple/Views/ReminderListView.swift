import SwiftUI
import ServiceManagement

enum ReminderFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case paused = "Paused"
}

struct ReminderListView: View {
    @Environment(ReminderStore.self) var store
    @Binding var path: NavigationPath
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

            Divider()

            Picker("Filter", selection: $selectedFilter) {
                ForEach(ReminderFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)

            if filteredReminders.isEmpty {
                Spacer()
                Text(emptyMessage)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredReminders) { reminder in
                            ReminderRowItem(
                                reminder: reminder,
                                store: store,
                                path: $path
                            )
                            Divider()
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
            HStack {
                Text("Launch at login")
                Spacer()
                if launchAtLogin {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                launchAtLogin.toggle()
                if launchAtLogin {
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

// MARK: - Row Item (separates NavigationLink from action buttons)

private struct ReminderRowItem: View {
    let reminder: Reminder
    let store: ReminderStore
    @Binding var path: NavigationPath

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 10) {
            NavigationLink(value: RippleDestination.detail(reminder.id)) {
                ReminderRowView(
                    reminder: reminder,
                    onToggle: { newValue in
                        var updated = reminder
                        updated.isEnabled = newValue
                        store.update(updated)
                    }
                )
            }
            .buttonStyle(.plain)

            Button(action: {
                path.append(RippleDestination.form(reminder.id))
            }) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Button(action: { showDeleteConfirmation = true }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .alert("Delete Reminder", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { store.delete(reminder) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(reminder.title)\"?")
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("With Reminders") {
    NavigationStack {
        ReminderListView(path: .constant(NavigationPath()))
    }
    .environment(previewStore())
    .frame(width: 320)
}

#Preview("Empty") {
    NavigationStack {
        ReminderListView(path: .constant(NavigationPath()))
    }
    .environment(previewStore(reminders: []))
    .frame(width: 320)
}

#Preview("Notifications Blocked") {
    NavigationStack {
        ReminderListView(path: .constant(NavigationPath()))
    }
    .environment(previewStoreBlocked())
    .frame(width: 320)
}
#endif
