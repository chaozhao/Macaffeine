import SwiftUI

@MainActor
struct SettingsView: View {
    @AppStorage(SettingsKey.defaultWakeDuration)
    private var defaultWakeDurationRaw = WakeDuration.oneHour.rawValue

    @AppStorage(SettingsKey.activateOnLaunch)
    private var activateOnLaunch = false

    @State private var launchAtLogin = LoginItemManager.isEnabled
    @State private var loginItemMessage = LoginItemManager.statusMessage
    @State private var showLoginItemHelp = LoginItemManager.requiresApproval

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            VStack(alignment: .leading, spacing: 18) {
                wakeSection
                launchSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)

            Spacer(minLength: 0)
        }
        .frame(width: 480, height: 400)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            refreshLoginItemState()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppMark(size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Macaffeine")
                    .font(.system(size: 15, weight: .semibold))
                Text("电源与启动设置")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text("v0.1")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var wakeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("系统唤醒")

            VStack(spacing: 0) {
                settingsRow {
                    Text("默认激活时长")
                        .font(.system(size: 13))

                    Spacer(minLength: 12)

                    Picker("默认激活时长", selection: $defaultWakeDurationRaw) {
                        ForEach(WakeDuration.allCases) { duration in
                            Text(duration.title).tag(duration.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }

                rowDivider

                settingsRow {
                    Text("启动应用后立刻激活系统")
                        .font(.system(size: 13))

                    Spacer(minLength: 12)

                    Toggle("启动应用后立刻激活系统", isOn: $activateOnLaunch)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            }
            .settingsCard()

            Text("开启后，Macaffeine 启动时会按默认时长自动保持系统唤醒。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)
        }
    }

    private var launchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("启动")

            VStack(spacing: 0) {
                settingsRow {
                    Text("开机时启动 Macaffeine")
                        .font(.system(size: 13))

                    Spacer(minLength: 12)

                    Toggle("开机时启动 Macaffeine", isOn: Binding(
                        get: { launchAtLogin },
                        set: { setLaunchAtLogin($0) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }

                if let loginItemMessage {
                    rowDivider

                    Text(loginItemMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                }

                if showLoginItemHelp {
                    rowDivider

                    HStack {
                        Button("打开登录项设置…") {
                            LoginItemManager.openLoginItemsSettings()
                        }
                        .font(.system(size: 11))
                        .buttonStyle(.link)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                }
            }
            .settingsCard()
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 2)
    }

    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 0) {
            content()
        }
        .frame(minHeight: 42)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.07))
            .frame(height: 1)
            .padding(.leading, 12)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LoginItemManager.setEnabled(enabled)
        } catch {
            loginItemMessage = "无法更新开机启动：\(error.localizedDescription)"
            refreshLoginItemState()
            showLoginItemHelp = true
            return
        }

        refreshLoginItemState()
    }

    private func refreshLoginItemState() {
        launchAtLogin = LoginItemManager.isEnabled
        showLoginItemHelp = LoginItemManager.requiresApproval
        loginItemMessage = LoginItemManager.statusMessage
    }
}

private extension View {
    func settingsCard() -> some View {
        background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
