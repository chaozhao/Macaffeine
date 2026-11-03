import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let appMenu = AppMenu()
    private let popover = NSPopover()
    private var outsideClickMonitor: Any?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
        configurePopover()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidResignActive(_:)),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if let outsideClickMonitor {
            NSEvent.removeMonitor(outsideClickMonitor)
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        let configuration = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        let image = NSImage(systemSymbolName: "power", accessibilityDescription: "PowerKeeper")?
            .withSymbolConfiguration(configuration)
        image?.isTemplate = true

        button.image = image
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = "PowerKeeper"
    }

    private func configurePopover() {
        let hostingController = NSHostingController(rootView: PopoverContentView())
        hostingController.view.layoutSubtreeIfNeeded()

        popover.contentViewController = hostingController
        popover.contentSize = NSSize(
            width: 336,
            height: max(hostingController.view.fittingSize.height, 200)
        )
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isSecondaryClick = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true

        if isSecondaryClick {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func showContextMenu() {
        closePopover()

        statusItem.menu = appMenu.menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func applicationDidResignActive(_ notification: Notification) {
        closePopover()
    }

    private func togglePopover() {
        if popover.isShown {
            closePopover()
            return
        }

        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        installOutsideClickMonitor()
    }

    private func closePopover() {
        removeOutsideClickMonitor()
        if popover.isShown {
            popover.performClose(nil)
        }
    }

    private func installOutsideClickMonitor() {
        guard outsideClickMonitor == nil else { return }

        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.closePopover()
            }
        }
    }

    private func removeOutsideClickMonitor() {
        guard let outsideClickMonitor else { return }
        NSEvent.removeMonitor(outsideClickMonitor)
        self.outsideClickMonitor = nil
    }

    func popoverDidClose(_ notification: Notification) {
        removeOutsideClickMonitor()
    }
}
