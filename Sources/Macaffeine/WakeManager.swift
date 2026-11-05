import AppKit
import Combine
import Foundation
import IOKit.pwr_mgt

enum WakeDuration: Int, CaseIterable, Identifiable {
    case thirtyMinutes
    case oneHour
    case twoHours
    case fiveHours
    case twelveHours
    case infinite

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .thirtyMinutes: return "30 分钟"
        case .oneHour: return "1 小时"
        case .twoHours: return "2 小时"
        case .fiveHours: return "5 小时"
        case .twelveHours: return "12 小时"
        case .infinite: return "无限激活"
        }
    }

    var timeInterval: TimeInterval? {
        switch self {
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        case .fiveHours: return 5 * 60 * 60
        case .twelveHours: return 12 * 60 * 60
        case .infinite: return nil
        }
    }
}

@MainActor
final class WakeManager: NSObject, ObservableObject {
    static let shared = WakeManager()

    @Published private(set) var activeDuration: WakeDuration?
    @Published private(set) var endDate: Date?
    @Published private(set) var now = Date()

    private var assertionID: IOPMAssertionID = 0
    private var timer: Timer?

    private override init() {
        super.init()
    }

    var isActive: Bool { activeDuration != nil }

    /// 菜单/弹窗中的状态标签，例如「未激活」「剩余 29:12」「无限激活」。
    var statusText: String {
        guard let activeDuration else { return "未激活" }
        guard activeDuration != .infinite else { return "无限激活" }
        return "剩余 \(remainingText ?? "--:--")"
    }

    /// 弹窗操作行的右侧文案。
    var detailText: String {
        guard let activeDuration else { return "未设置" }
        guard activeDuration != .infinite else { return "无限激活" }
        return "剩余 \(remainingText ?? "--:--")"
    }

    var remainingText: String? {
        guard let endDate else { return nil }
        return TimeFormat.remaining(from: now, to: endDate)
    }

    /// 再次选择当前时长会取消激活，方便快速关闭。
    func activate(_ duration: WakeDuration) {
        if activeDuration == duration {
            deactivate()
            return
        }

        releaseAssertion()
        guard acquireAssertion() else { return }

        let start = Date()
        activeDuration = duration
        now = start
        endDate = duration.timeInterval.map { start.addingTimeInterval($0) }
        startTimerIfNeeded()
    }

    func deactivate() {
        releaseAssertion()
        timer?.invalidate()
        timer = nil
        activeDuration = nil
        endDate = nil
    }

    /// 在指定位置弹出时长选择菜单。
    func presentDurationMenu(in view: NSView, at point: NSPoint) {
        let menu = NSMenu()
        menu.autoenablesItems = false

        for duration in WakeDuration.allCases {
            let item = NSMenuItem(
                title: duration.title,
                action: #selector(selectDurationFromMenu(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = duration.rawValue
            item.state = duration == activeDuration ? .on : .off
            menu.addItem(item)
        }

        if isActive {
            menu.addItem(.separator())

            let stopItem = NSMenuItem(
                title: "停止激活",
                action: #selector(stopWakeFromMenu(_:)),
                keyEquivalent: ""
            )
            stopItem.target = self
            menu.addItem(stopItem)
        }

        menu.popUp(positioning: nil, at: point, in: view)
    }

    @objc private func selectDurationFromMenu(_ sender: NSMenuItem) {
        guard let duration = WakeDuration(rawValue: sender.tag) else { return }
        activate(duration)
    }

    @objc private func stopWakeFromMenu(_ sender: NSMenuItem) {
        deactivate()
    }

    private func acquireAssertion() -> Bool {
        let reason = "Macaffeine 正在保持系统唤醒" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )

        guard result == kIOReturnSuccess else {
            assertionID = 0
            NSLog("Macaffeine: 创建防休眠断言失败 (%d)", result)
            return false
        }
        return true
    }

    private func releaseAssertion() {
        guard assertionID != 0 else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = 0
    }

    private func startTimerIfNeeded() {
        timer?.invalidate()
        timer = nil

        guard endDate != nil else { return }

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
        if let endDate, now >= endDate {
            deactivate()
        }
    }

    deinit {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
        }
    }
}
