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

// MARK: - Navigation

enum RippleDestination: Hashable {
    case detail(UUID)
    case form(UUID?)  // nil = add, UUID = edit
}

// MARK: - Root View

struct ContentView: View {
    @Environment(ReminderStore.self) var store
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ReminderListView()
                .navigationDestination(for: RippleDestination.self) { destination in
                    switch destination {
                    case .detail(let id):
                        if let reminder = store.reminders.first(where: { $0.id == id }) {
                            ReminderDetailView(reminder: reminder)
                        }
                    case .form(let id):
                        if let id, let reminder = store.reminders.first(where: { $0.id == id }) {
                            ReminderFormView(reminder: reminder, path: $path)
                        } else {
                            ReminderFormView(path: $path)
                        }
                    }
                }
        }
        .frame(width: 320)
        .frame(minHeight: 200, maxHeight: 600)
    }
}
