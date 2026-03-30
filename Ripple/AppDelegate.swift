import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var store = ReminderStore()
    var engine: SchedulerEngine!
    var delivery: DeliveryManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenubarIcon()
        setupScheduler()
        setupPopover()
        updateMenubarIcon()
        observeStoreChanges()
    }

    private func setupMenubarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Ripple")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environment(store)
                .environment(\.schedulerEngine, engine)
        )
    }

    private func setupScheduler() {
        delivery = DeliveryManager(
            statusButton: statusItem.button,
            onSnooze: { [weak self] id, duration in
                self?.engine.snooze(id, duration: duration)
            },
            onNotificationsBlocked: { [weak self] in
                DispatchQueue.main.async { self?.store.notificationsBlocked = true }
            },
            onFlashComplete: { [weak self] in
                self?.updateMenubarIcon()
            }
        )
        delivery.requestAuthorization()
        engine = SchedulerEngine(store: store, delivery: delivery)
        engine.start()
    }

    func updateMenubarIcon() {
        let hasActive = store.reminders.contains { $0.isEnabled }
        let symbolName = hasActive ? "bell.badge.fill" : "bell.fill"
        statusItem.button?.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: "Ripple"
        )
    }

    private func observeStoreChanges() {
        withObservationTracking {
            _ = store.reminders
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.updateMenubarIcon()
                self?.observeStoreChanges()
            }
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button, popover != nil else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
