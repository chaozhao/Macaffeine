# PowerKeeper

PowerKeeper 是一个轻量的 macOS 菜单栏电源管理工具，把“保持唤醒、立刻熄屏、定时关机”放在一个弹窗里，不需要打开系统设置来回切换。

应用常驻菜单栏，不显示 Dock 图标。

## 功能

- **保持系统唤醒**：通过 IOKit 电源断言阻止系统空闲休眠，可选 30 分钟、1 小时、2 小时、5 小时、12 小时或无限激活；再次选择当前时长即可停止。
- **立刻熄屏**：仅关闭显示器，系统和其他任务继续运行。
- **自动关机**：可选 30 分钟、1 小时后或 2 小时后自动关机，弹窗和菜单中显示倒计时。
- **开机启动**：基于 `SMAppService` 注册为登录项，可随时开启或关闭。
- **启动行为设置**：设置默认激活时长，并可在应用启动后自动保持系统唤醒。
- **两种菜单入口**：左键点击菜单栏图标打开控制弹窗，右键打开快捷菜单。

## 环境要求

- macOS 13.0 或更高版本
- Xcode Command Line Tools（包含 Swift 5.9+）

## 构建

在项目根目录执行：

```bash
./build.sh
```

脚本会以 Release 配置构建应用，生成 `dist/PowerKeeper.app`，并进行本地临时签名。

运行：

```bash
open dist/PowerKeeper.app
```

如果系统阻止打开，可在“系统设置 → 隐私与安全性”中允许运行。

如需使用开机启动，建议先将应用移动到“应用程序”文件夹：

```bash
cp -R dist/PowerKeeper.app /Applications/
open /Applications/PowerKeeper.app
```

## 使用

启动后，图标会出现在菜单栏：

- **左键点击**：打开控制弹窗，可设置保持唤醒时长、立刻熄屏或安排自动关机。
- **右键点击**：打开快捷菜单，查看当前状态、进入设置或退出应用。

### 权限说明

- 自动关机会通过 AppleScript 调用 `System Events`。首次使用时，macOS 会请求自动化权限；如果拒绝，需要在“系统设置 → 隐私与安全性 → 自动化”中重新允许。
- 开启开机启动后，系统可能要求在“系统设置 → 通用 → 登录项”中确认 PowerKeeper。

## 项目结构

```text
.
├── Package.swift                 # Swift Package 配置
├── Resources/
│   ├── AppIcon.icns              # 应用图标
│   └── Info.plist                # 应用元信息
├── Sources/PowerKeeper/
│   ├── PowerKeeperApp.swift      # 应用入口
│   ├── AppDelegate.swift         # 生命周期
│   ├── StatusBarController.swift # 菜单栏图标与弹窗
│   ├── PopoverContentView.swift  # 控制弹窗界面
│   ├── AppMenu.swift             # 右键快捷菜单
│   ├── SettingsView.swift        # 设置界面
│   ├── SettingsWindowController.swift
│   ├── WakeManager.swift         # 防休眠与倒计时
│   ├── ShutdownManager.swift     # 定时关机
│   ├── DisplayController.swift   # 显示器休眠
│   ├── LoginItemManager.swift    # 开机启动
│   ├── AppSettings.swift         # 用户偏好
│   ├── Theme.swift               # 界面主题
│   └── TimeFormat.swift          # 时间格式化
├── Tools/
│   └── generate_app_icon.swift   # 图标生成脚本
└── build.sh                      # 打包脚本
```

## 技术说明

- 原生 Swift + AppKit / SwiftUI，无第三方运行时依赖。
- 使用 Swift Package Manager 构建可执行文件，再由 `build.sh` 组装为 `.app` 发布包，无需 Xcode 工程。
- 防休眠使用 `IOPMAssertionCreateWithName`，熄屏使用 `pmset displaysleepnow`，自动关机使用 `osascript`。
- 设置项保存在 `UserDefaults` 中。
