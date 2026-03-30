import Foundation

extension Reminder {
    /// Subtitle for list rows — e.g. "Every 45 min · 9am–6pm" or "Today at 10:00 AM"
    var subtitle: String {
        switch type {
        case .recurring:
            let interval = intervalLabel
            let hours = activeHoursLabel
            return hours == "All day" ? interval : "\(interval) · \(hours)"
        case .oneTime:
            guard let date = scheduledDate else { return "" }
            if Calendar.current.isDateInToday(date) {
                let formatter = DateFormatter()
                formatter.dateFormat = "'Today at' h:mm a"
                return formatter.string(from: date)
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d 'at' h:mm a"
            return formatter.string(from: date)
        }
    }

    /// "Every 45 min" or "Every 2 hr"
    var intervalLabel: String {
        guard let mins = intervalMinutes else { return "" }
        if mins >= 60 && mins % 60 == 0 {
            return "Every \(mins / 60) hr"
        }
        return "Every \(mins) min"
    }

    /// "9am – 5pm" or "All day"
    var activeHoursLabel: String {
        guard let start = activeHoursStart, let end = activeHoursEnd else { return "All day" }
        return "\(formatMinutes(start)) – \(formatMinutes(end))"
    }

    /// "Mon – Fri" or "Every day" or "Mon, Wed, Fri"
    var activeDaysLabel: String {
        guard let days = activeDays else { return "Every day" }
        if days.count == 7 { return "Every day" }
        let weekdays: Set<Weekday> = [.mon, .tue, .wed, .thu, .fri]
        if days == weekdays { return "Mon – Fri" }
        let sorted = days.sorted { $0.rawValue < $1.rawValue }
        return sorted.map { $0.shortName }.joined(separator: ", ")
    }

    /// "Snooze 5 min" or "Snooze off"
    var snoozeLabel: String {
        guard let mins = snoozeDurationMinutes else { return "Snooze off" }
        return "Snooze \(mins) min"
    }

    private func formatMinutes(_ totalMinutes: Int) -> String {
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        let period = h < 12 ? "am" : "pm"
        let displayH: Int
        if h == 0 { displayH = 12 }
        else if h > 12 { displayH = h - 12 }
        else { displayH = h }
        if m == 0 {
            return "\(displayH)\(period)"
        }
        return String(format: "%d:%02d%@", displayH, m, period)
    }
}

extension Weekday {
    var shortName: String {
        switch self {
        case .mon: return "Mon"
        case .tue: return "Tue"
        case .wed: return "Wed"
        case .thu: return "Thu"
        case .fri: return "Fri"
        case .sat: return "Sat"
        case .sun: return "Sun"
        }
    }

    var letter: String {
        switch self {
        case .mon: return "M"
        case .tue: return "T"
        case .wed: return "W"
        case .thu: return "T"
        case .fri: return "F"
        case .sat: return "S"
        case .sun: return "S"
        }
    }
}
