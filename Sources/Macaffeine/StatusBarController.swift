import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let appMenu = AppMenu()
    private let popover = NSPopover()
    private var outsideClickMonitor: Any?
    private var localClickMonitor: Any?
    private var localKeyMonitor: Any?
    private var isFadingOut = false
    private var isClosingProgrammatically = false

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
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
        }
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        let configuration = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        let image = NSImage(systemSymbolName: "power", accessibilityDescription: "Macaffeine")?
            .withSymbolConfiguration(configuration)
        image?.isTemplate = true

        button.image = image
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = "Macaffeine"
    }

    private func configurePopover() {
        let hostingController = NSHostingController(rootView: PopoverContentView())
        hostingController.view.layoutSubtreeIfNeeded()

        popover.contentViewController = hostingController
        popover.contentSize = NSSize(
            width: 336,
            height: max(hostingController.view.fittingSize.height, 200)
        )
        popover.behavior = .applicationDefined
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
        closePopover(animated: false)

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
        popover.contentViewController?.view.window?.alphaValue = 1
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        installOutsideClickMonitor()
    }

    private func closePopover(animated: Bool = true) {
        removeOutsideClickMonitor()

        guard popover.isShown else { return }
        guard !isFadingOut else { return }

        guard animated, let window = popover.contentViewController?.view.window else {
            performClose()
            return
        }

        isFadingOut = true
        // 关闭时禁用 NSPopover 默认的收起动画，改由我们在原地淡出。
        popover.animates = false

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.26
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                self?.performClose()
            }
        }
    }

    private func performClose() {
        popover.animates = false
        isClosingProgrammatically = true
        popover.performClose(nil)
        isClosingProgrammatically = false

        popover.contentViewController?.view.window?.alphaValue = 1
        popover.animates = true
        isFadingOut = false
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

        localClickMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleLocalClick(event)
            }
            return event
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            var handled = false
            MainActor.assumeIsolated {
                guard let self, event.keyCode == 53 else { return }
                if self.popover.isShown && !self.hasOpenMenu {
                    self.closePopover()
                    handled = true
                }
            }
            return handled ? nil : event
        }
    }

    private func removeOutsideClickMonitor() {
        if let outsideClickMonitor {
            NSEvent.removeMonitor(outsideClickMonitor)
            self.outsideClickMonitor = nil
        }
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
    }

    private func handleLocalClick(_ event: NSEvent) {
        guard popover.isShown, !isFadingOut else { return }
        guard let window = event.window else { return }

        if window === popover.contentViewController?.view.window { return }
        if window === statusItem.button?.window { return }
        if isMenuWindow(window) { return }

        closePopover()
    }

    private var hasOpenMenu: Bool {
        NSApp.windows.contains { $0.isVisible && isMenuWindow($0) }
    }

    private func isMenuWindow(_ window: NSWindow) -> Bool {
        // NSMenu 使用独立窗口，类名包含 "Menu"；弹窗自身是 NSPopoverWindow。
        window.className.localizedCaseInsensitiveContains("menu")
    }

    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        guard popover === self.popover else { return true }
        guard !isClosingProgrammatically else { return true }
        if isFadingOut { return false }
        guard popover.isShown else { return true }

        closePopover()
        return false
    }

    func popoverDidClose(_ notification: Notification) {
        removeOutsideClickMonitor()
        isFadingOut = false
        isClosingProgrammatically = false
        popover.animates = true
        popover.contentViewController?.view.window?.alphaValue = 1
    }
}
