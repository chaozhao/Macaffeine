import Foundation
import ServiceManagement

@MainActor
enum LoginItemManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static var requiresApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    static var statusMessage: String? {
        switch SMAppService.mainApp.status {
        case .enabled:
            return nil
        case .requiresApproval:
            return "已注册，需要在“系统设置 → 通用 → 登录项”中允许 PowerKeeper。"
        case .notFound:
            return "系统未找到应用，请把 PowerKeeper.app 移动到“应用程序”文件夹后再试。"
        case .notRegistered:
            return nil
        @unknown default:
            return nil
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    static func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
