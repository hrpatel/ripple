import AppKit
import UserNotifications

protocol DeliveryManagerProtocol {
    func deliver(_ reminder: Reminder)
}

final class DeliveryManager: NSObject, DeliveryManagerProtocol {
    private weak var statusButton: NSStatusBarButton?
    private let onSnooze: (UUID, Int) -> Void
    private let onNotificationsBlocked: () -> Void
    private let onFlashComplete: () -> Void
    private let snoozePresets = [1, 5, 10, 15, 30]

    init(
        statusButton: NSStatusBarButton?,
        onSnooze: @escaping (UUID, Int) -> Void,
        onNotificationsBlocked: @escaping () -> Void,
        onFlashComplete: @escaping () -> Void
    ) {
        self.statusButton = statusButton
        self.onSnooze = onSnooze
        self.onNotificationsBlocked = onNotificationsBlocked
        self.onFlashComplete = onFlashComplete
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        var categories = Set<UNNotificationCategory>()
        for minutes in snoozePresets {
            let action = UNNotificationAction(
                identifier: "SNOOZE",
                title: "Snooze \(minutes) min"
            )
            let category = UNNotificationCategory(
                identifier: "REMINDER_\(minutes)",
                actions: [action],
                intentIdentifiers: []
            )
            categories.insert(category)
        }
        UNUserNotificationCenter.current().setNotificationCategories(categories)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func deliver(_ reminder: Reminder) {
        if reminder.delivery.notification {
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                if settings.authorizationStatus == .denied {
                    self?.onNotificationsBlocked()
                } else {
                    self?.sendNotification(for: reminder)
                }
            }
        }
        if reminder.delivery.sound {
            NSSound(named: .init("Glass"))?.play()
        }
        if reminder.delivery.menubarIconFlash {
            flashMenubarIcon()
        }
    }

    private func sendNotification(for reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        if let duration = reminder.snoozeDurationMinutes {
            content.categoryIdentifier = "REMINDER_\(duration)"
        }
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func flashMenubarIcon() {
        DispatchQueue.main.async { [weak self] in
            var count = 0
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
                count += 1
                let filled = count % 2 == 0
                self?.statusButton?.image = NSImage(
                    systemSymbolName: filled ? "bell.fill" : "bell",
                    accessibilityDescription: nil
                )
                if count >= 8 {
                    timer.invalidate()
                    self?.onFlashComplete()
                }
            }
        }
    }
}

extension DeliveryManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "SNOOZE",
           let id = UUID(uuidString: response.notification.request.identifier) {
            // Extract duration from categoryIdentifier (e.g. "REMINDER_5" → 5)
            let category = response.notification.request.content.categoryIdentifier
            let duration = Int(category.replacingOccurrences(of: "REMINDER_", with: "")) ?? 5
            onSnooze(id, duration)
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
