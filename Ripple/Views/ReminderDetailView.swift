import SwiftUI

struct ReminderDetailView: View {
    let reminder: Reminder
    @Environment(\.schedulerEngine) var engine
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Back button
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)

            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(reminder.type == .recurring ? "Recurring reminder" : "One-time reminder")
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Info fields
            if reminder.type == .recurring {
                infoGrid(rows: [
                    ("INTERVAL", reminder.intervalLabel),
                    ("ACTIVE HOURS", reminder.activeHoursLabel),
                    ("DAYS", reminder.activeDaysLabel),
                    ("NEXT TRIGGER", nextTriggerLabel),
                ])
            } else {
                infoGrid(rows: [
                    ("SCHEDULED", scheduledLabel),
                    ("STATUS", reminder.isEnabled ? "Pending" : "Fired"),
                ])
            }

            Divider()

            // Delivery tags
            Text("DELIVERY")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                deliveryTag("Notification", isActive: reminder.delivery.notification)
                deliveryTag("Sound", isActive: reminder.delivery.sound)
                deliveryTag("Menubar Icon", isActive: reminder.delivery.menubarIconFlash)
            }

            // Snooze
            Text("SNOOZE")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(reminder.snoozeLabel)
                .font(.subheadline)

            Spacer()

            // Edit button placeholder
            HStack {
                Spacer()
                NavigationLink(value: RippleDestination.form(reminder.id)) {
                    Text("Edit reminder")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                Spacer()
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private var nextTriggerLabel: String {
        guard reminder.isEnabled else { return "Paused" }
        guard let next = engine?.nextFireDate(for: reminder) else { return "—" }
        return next.formatted(date: .omitted, time: .shortened)
    }

    private var scheduledLabel: String {
        guard let date = reminder.scheduledDate else { return "—" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func infoGrid(rows: [(String, String)]) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
            ForEach(rows, id: \.0) { label, value in
                GridRow {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 100, alignment: .leading)
                    Text(value)
                }
            }
        }
    }

    private func deliveryTag(_ title: String, isActive: Bool) -> some View {
        Text(title)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .foregroundStyle(isActive ? .green : .secondary)
    }
}
