import Foundation

struct Reminder: Identifiable, Codable {
    var id: UUID
    var title: String
    var type: ReminderType
    var intervalMinutes: Int?
    var scheduledDate: Date?
    var activeHoursStart: Date?
    var activeHoursEnd: Date?
    var activeDays: Set<Weekday>
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

enum Weekday: Int, Codable, CaseIterable {
    case mon = 1, tue, wed, thu, fri, sat, sun
}
