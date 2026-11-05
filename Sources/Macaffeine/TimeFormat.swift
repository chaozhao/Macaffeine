import Foundation

enum TimeFormat {
    static func remaining(from now: Date, to endDate: Date) -> String {
        let seconds = max(0, Int(endDate.timeIntervalSince(now).rounded(.up)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}
