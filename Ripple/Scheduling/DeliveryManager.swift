import AppKit
import UserNotifications

protocol DeliveryManagerProtocol {
    func deliver(_ reminder: Reminder)
}

final class DeliveryManager: NSObject, DeliveryManagerProtocol {
    private weak var statusButton: NSStatusBarButton?
    private let onSnooze: (UUID) -> Void
    private let onNotificationsBlocked: () -> Void

    init(
        statusButton: NSStatusBarButton?,
        onSnooze: @escaping (UUID) -> Void,
        onNotificationsBlocked: @escaping () -> Void
    ) {
        self.statusButton = statusButton
        self.onSnooze = onSnooze
        self.onNotificationsBlocked = onNotificationsBlocked
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE", title: "Snooze")
        let category = UNNotificationCategory(
            identifier: "REMINDER",
            actions: [snoozeAction],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
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
        if reminder.snoozeEnabled {
            content.categoryIdentifier = "REMINDER"
        }
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func flashMenubarIcon() {
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
                self?.statusButton?.image = NSImage(
                    systemSymbolName: "bell.fill",
                    accessibilityDescription: nil
                )
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
            onSnooze(id)
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
