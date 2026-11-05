import AppKit
import Combine
import Foundation

enum ShutdownDelay: Int, CaseIterable, Identifiable {
    case none
    case thirtyMinutes
    case oneHour
    case twoHours

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .none: return "不自动关机"
        case .thirtyMinutes: return "30 分钟后"
        case .oneHour: return "1 小时后"
        case .twoHours: return "2 小时后"
        }
    }

    var timeInterval: TimeInterval? {
        switch self {
        case .none: return nil
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        }
    }
}

@MainActor
final class ShutdownManager: NSObject, ObservableObject {
    static let shared = ShutdownManager()

    @Published private(set) var scheduledDelay: ShutdownDelay?
    @Published private(set) var endDate: Date?
    @Published private(set) var now = Date()

    private var timer: Timer?

    private override init() {
        super.init()
    }

    var isScheduled: Bool { endDate != nil }

    /// 菜单/弹窗中的状态标签，例如「未设置」「剩余 29:12」。
    var statusText: String {
        guard let endDate else { return "未设置" }
        return "剩余 \(TimeFormat.remaining(from: now, to: endDate))"
    }

    /// 弹窗操作行的右侧文案。
    var detailText: String {
        guard endDate != nil else { return "已关闭" }
        return statusText
    }

    /// 取消当前计划并重新安排；传入 `.none` 表示取消。
    func schedule(_ delay: ShutdownDelay) {
        cancel()

        guard let interval = delay.timeInterval else { return }

        let start = Date()
        endDate = start.addingTimeInterval(interval)
        scheduledDelay = delay
        now = start
        startTimer()
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        scheduledDelay = nil
        endDate = nil
    }

    /// 在指定位置弹出关机时间菜单。
    func presentMenu(in view: NSView, at point: NSPoint) {
        let menu = NSMenu()
        menu.autoenablesItems = false

        for delay in ShutdownDelay.allCases {
            let item = NSMenuItem(
                title: delay.title,
                action: #selector(selectDelayFromMenu(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = delay.rawValue
            item.state = delay == scheduledDelay ? .on : .off
            menu.addItem(item)
        }

        menu.popUp(positioning: nil, at: point, in: view)
    }

    @objc private func selectDelayFromMenu(_ sender: NSMenuItem) {
        guard let delay = ShutdownDelay(rawValue: sender.tag) else { return }
        schedule(delay)
    }

    private func startTimer() {
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        now = Date()

        guard let endDate, now >= endDate else { return }

        timer?.invalidate()
        timer = nil
        scheduledDelay = nil
        self.endDate = nil

        performShutdown()
    }

    private func performShutdown() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "tell application \"System Events\" to shut down"]
        process.terminationHandler = { [weak self] process in
            guard process.terminationStatus != 0 else { return }
            Task { @MainActor in
                self?.reportShutdownFailure()
            }
        }

        do {
            try process.run()
        } catch {
            NSLog("Macaffeine: 无法执行自动关机 - %@", error.localizedDescription)
            reportShutdownFailure()
        }
    }

    private func reportShutdownFailure() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "自动关机失败"
        alert.informativeText = "请在“系统设置 → 隐私与安全性 → 自动化”中允许 Macaffeine 控制 System Events，然后重新设置自动关机。"
        alert.alertStyle = .warning
        alert.runModal()
    }
}
