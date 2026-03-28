import SwiftUI

struct ReminderRowView: View {
    let reminder: Reminder
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { reminder.isEnabled },
                set: { onToggle($0) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .fontWeight(.medium)
                Text(reminder.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(reminder.type == .recurring ? "recurring" : "one-time")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(reminder.type == .recurring
                            ? Color.green.opacity(0.2)
                            : Color.teal.opacity(0.2))
                )
                .foregroundStyle(reminder.type == .recurring ? .green : .teal)
        }
        .padding(.vertical, 4)
    }
}
