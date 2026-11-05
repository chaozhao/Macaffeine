import AppKit

@MainActor
enum DisplayController {
    /// 立即让显示器进入睡眠，系统本身保持运行。
    static func sleepDisplay() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["displaysleepnow"]

        do {
            try process.run()
        } catch {
            NSLog("Macaffeine: 熄屏失败 - %@", error.localizedDescription)
        }
    }
}
