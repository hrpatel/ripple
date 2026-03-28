import SwiftUI

// MARK: - SchedulerEngine EnvironmentKey

struct SchedulerEngineKey: EnvironmentKey {
    static let defaultValue: SchedulerEngine? = nil
}

extension EnvironmentValues {
    var schedulerEngine: SchedulerEngine? {
        get { self[SchedulerEngineKey.self] }
        set { self[SchedulerEngineKey.self] = newValue }
    }
}

// MARK: - Root View

struct ContentView: View {
    @Environment(ReminderStore.self) var store

    var body: some View {
        NavigationStack {
            ReminderListView()
                .navigationDestination(for: UUID.self) { id in
                    if let reminder = store.reminders.first(where: { $0.id == id }) {
                        ReminderDetailView(reminder: reminder)
                    }
                }
        }
        .frame(minWidth: 320, minHeight: 400)
    }
}
