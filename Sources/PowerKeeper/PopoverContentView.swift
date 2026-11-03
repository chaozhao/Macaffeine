import AppKit
import SwiftUI

@MainActor
struct PopoverContentView: View {
    @ObservedObject private var wakeManager = WakeManager.shared
    @ObservedObject private var shutdownManager = ShutdownManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            sectionLabel("电源控制")
                .padding(.top, 6)

            controlCard
                .padding(.horizontal, 12)

            footer
                .padding(.top, 10)
        }
        .frame(width: 336)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 11) {
            AppMark(size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("PowerKeeper")
                    .font(.system(size: 14, weight: .semibold))
                Text("保持唤醒 · 熄屏 · 定时关机")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var controlCard: some View {
        VStack(spacing: 0) {
            ControlRow(
                icon: "timer",
                tint: AppTheme.amber,
                title: "激活系统时长",
                detail: wakeManager.detailText,
                showsActive: wakeManager.isActive,
                help: "选择保持系统唤醒的时长"
            ) {
                openWakeDurationMenu()
            }

            cardDivider

            ControlRow(
                icon: "display",
                tint: AppTheme.blue,
                title: "立刻熄屏",
                showsChevron: false,
                help: "立即关闭显示器，系统继续运行"
            ) {
                DisplayController.sleepDisplay()
            }

            cardDivider

            ControlRow(
                icon: "power",
                tint: AppTheme.red,
                title: "自动关机",
                detail: shutdownManager.detailText,
                showsActive: shutdownManager.scheduledDelay != nil,
                help: "选择倒计时结束后自动关机"
            ) {
                openShutdownMenu()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var cardDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.07))
            .frame(height: 1)
            .padding(.leading, 46)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.primary.opacity(0.07))
                .frame(height: 1)
                .padding(.top, 2)

            HStack {
                Text("v0.1")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)

                Spacer()

                QuitButton()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
        }
    }

    private func openWakeDurationMenu() {
        presentMenuAtClickPoint { view, point in
            wakeManager.presentDurationMenu(in: view, at: point)
        }
    }

    private func openShutdownMenu() {
        presentMenuAtClickPoint { view, point in
            shutdownManager.presentMenu(in: view, at: point)
        }
    }

    private func presentMenuAtClickPoint(_ present: (NSView, NSPoint) -> Void) {
        guard let window = NSApp.currentEvent?.window
            ?? NSApp.keyWindow
            ?? NSApp.windows.first(where: { $0.isVisible }),
            let contentView = window.contentView else { return }

        let point: NSPoint
        if let event = NSApp.currentEvent, event.window === window {
            point = contentView.convert(event.locationInWindow, from: nil)
        } else {
            let windowPoint = window.convertPoint(fromScreen: NSEvent.mouseLocation)
            point = contentView.convert(windowPoint, from: nil)
        }

        present(contentView, point)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 18)
            .padding(.bottom, 6)
    }
}

private struct ControlRow: View {
    let icon: String
    let tint: Color
    let title: String
    var detail: String?
    var showsActive = false
    var showsChevron = true
    var help: String?
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ControlRowLabel(
                icon: icon,
                tint: tint,
                title: title,
                detail: detail,
                showsActive: showsActive,
                showsChevron: showsChevron
            )
        }
        .buttonStyle(.plain)
        .help(help ?? title)
    }
}

private struct ControlRowLabel: View {
    let icon: String
    let tint: Color
    let title: String
    var detail: String?
    var showsActive = false
    var showsChevron = true

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(
                    tint.opacity(0.14),
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            if let detail {
                HStack(spacing: 5) {
                    if showsActive {
                        Circle()
                            .fill(tint)
                            .frame(width: 5, height: 5)
                    }

                    Text(detail)
                        .font(.system(size: 11, weight: showsActive ? .medium : .regular))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
                .opacity(showsChevron ? 1 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .frame(height: 44)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
                .padding(.horizontal, 4)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct QuitButton: View {
    @State private var isHovered = false

    var body: some View {
        Button {
            NSApp.terminate(nil)
        } label: {
            Text("退出")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(isHovered ? Color.primary.opacity(0.07) : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
