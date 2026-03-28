import Foundation

struct Reminder: Identifiable, Codable {
    var id: UUID
    var title: String
    var type: ReminderType
    var intervalMinutes: Int?
    var scheduledDate: Date?
    var activeHoursStart: Int?  // minutes since midnight, e.g. 540 = 09:00
    var activeHoursEnd: Int?    // minutes since midnight, e.g. 1020 = 17:00
    var activeDays: Set<Weekday>?
    var isEnabled: Bool
    var delivery: DeliveryOptions
    var snoozeEnabled: Bool
}

enum ReminderType: String, Codable {
    case recurring
    case oneTime
}

struct DeliveryOptions: Codable {
    var notification: Bool
    var sound: Bool
    var menubarIconFlash: Bool
}

/// Monday = 1. Note: this differs from `Calendar.weekday` (where Sunday = 1).
/// Use `Weekday.rawValue` only for persistence; convert explicitly when comparing with Calendar.
enum Weekday: Int, Codable, CaseIterable {
    case mon = 1, tue, wed, thu, fri, sat, sun
}

extension Reminder {
    var isValid: Bool {
        switch type {
        case .recurring: return intervalMinutes != nil
        case .oneTime:   return scheduledDate != nil
        }
    }
}
