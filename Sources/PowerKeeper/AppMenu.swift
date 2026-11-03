import AppKit

@MainActor
final class AppMenu: NSObject, NSMenuDelegate {
    let menu = NSMenu()

    private let wakeManager = WakeManager.shared
    private let shutdownManager = ShutdownManager.shared
    private let wakeHeaderView = StatusHeaderView()
    private let shutdownHeaderView = StatusHeaderView()

    override init() {
        super.init()
        configureMenu()
        refreshStates()
    }

    private func configureMenu() {
        menu.autoenablesItems = false
        menu.delegate = self

        let statusHeader = NSMenuItem()
        statusHeader.view = wakeHeaderView
        menu.addItem(statusHeader)

        let shutdownHeader = NSMenuItem()
        shutdownHeader.view = shutdownHeaderView
        menu.addItem(shutdownHeader)

        menu.addItem(.separator())
        menu.addItem(makeItem(
            title: "设置…",
            symbol: "gearshape",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        menu.addItem(.separator())
        menu.addItem(makeItem(
            title: "退出 PowerKeeper",
            symbol: "rectangle.portrait.and.arrow.right",
            action: #selector(quit),
            keyEquivalent: "q"
        ))
    }

    func menuWillOpen(_ menu: NSMenu) {
        guard menu === self.menu else { return }
        refreshStates()
    }

    private func refreshStates() {
        let wakeStatus: String
        let wakeTime: String
        if wakeManager.isActive {
            if wakeManager.activeDuration == .infinite {
                wakeStatus = "无限激活"
                wakeTime = ""
            } else {
                wakeStatus = "剩余"
                wakeTime = wakeManager.remainingText ?? "--:--"
            }
        } else {
            wakeStatus = "未激活"
            wakeTime = ""
        }
        wakeHeaderView.update(title: "系统唤醒", status: wakeStatus, time: wakeTime)

        let shutdownTime = shutdownManager.endDate
            .map { TimeFormat.remaining(from: shutdownManager.now, to: $0) } ?? ""
        shutdownHeaderView.update(
            title: "自动关机",
            status: shutdownManager.isScheduled ? "剩余" : "未设置",
            time: shutdownTime
        )
    }

    private func makeItem(
        title: String,
        symbol: String,
        action: Selector? = nil,
        keyEquivalent: String = "",
        submenu: NSMenu? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)

        if let submenu {
            item.submenu = submenu
        } else {
            item.target = self
        }

        if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
            image.isTemplate = true
            item.image = image
        }

        return item
    }

    @objc private func openSettings(_ sender: NSMenuItem) {
        SettingsWindowController.shared.show()
    }

    @objc private func quit(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }
}

@MainActor
final class StatusHeaderView: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")

    override var intrinsicContentSize: NSSize {
        NSSize(
            width: 40 + titleLabel.intrinsicContentSize.width + 16
                + statusLabel.intrinsicContentSize.width + 8
                + timeLabel.intrinsicContentSize.width,
            height: 22
        )
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(x: 0, y: 0, width: 220, height: 22))
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String, status: String, time: String) {
        titleLabel.stringValue = title
        statusLabel.stringValue = status
        timeLabel.stringValue = time
        invalidateIntrinsicContentSize()
    }

    private func setup() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = NSFont.menuFont(ofSize: 13)
        titleLabel.textColor = NSColor.secondaryLabelColor
        titleLabel.lineBreakMode = .byTruncatingTail

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = NSFont.menuFont(ofSize: 13)
        statusLabel.textColor = NSColor.secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = NSColor.secondaryLabelColor
        timeLabel.alignment = .right
        timeLabel.lineBreakMode = .byTruncatingTail

        addSubview(titleLabel)
        addSubview(statusLabel)
        addSubview(timeLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 16),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),
            heightAnchor.constraint(equalToConstant: 22)
        ])
    }
}
