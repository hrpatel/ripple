import SwiftUI

enum ReminderFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case paused = "Paused"
}

struct ReminderListView: View {
    @Environment(ReminderStore.self) var store
    @State private var selectedFilter: ReminderFilter = .all

    var filteredReminders: [Reminder] {
        switch selectedFilter {
        case .all: return store.reminders
        case .active: return store.reminders.filter { $0.isEnabled }
        case .paused: return store.reminders.filter { !$0.isEnabled }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
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
