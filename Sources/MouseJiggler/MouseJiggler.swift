import SwiftUI

@main
struct MouseJigglerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            EmptyView()
                .hidden()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var keyboardMonitor: Any?

    @Published var isJigglerActive = false

    nonisolated func applicationDidFinishLaunching(_: Notification) {
        Task { @MainActor in
            self.setup()
        }
    }

    private func setup() {
        self.setupMenuBar()
        self.setupKeyboardShortcut()
        self.setupIconChangeListener()
        NSApp.setActivationPolicy(.accessory)
    }

    private func setupMenuBar() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.updateMenuBarIcon()

        guard let button = statusItem?.button else { return }
        button.action = #selector(self.togglePopover)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        self.setupPopover()
    }

    @objc private func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }
        let style = Settings.shared.menuBarIconStyle
        button.image = NSImage(
            systemSymbolName: style.systemImage,
            accessibilityDescription: "Mouse Jiggler"
        )
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 420)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView().environmentObject(self)
        )
        self.popover = popover
    }

    private func setupIconChangeListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.updateMenuBarIcon),
            name: .menuBarIconChanged,
            object: nil
        )
    }

    @objc private func updateMenuBarIconNotification() {
        self.updateMenuBarIcon()
    }

    @objc private func togglePopover() {
        if let button = statusItem?.button {
            if self.popover?.isShown == true {
                self.popover?.performClose(nil)
            } else {
                self.popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    @objc func toggleJiggler() {
        self.isJigglerActive.toggle()
        NotificationCenter.default.post(name: .toggleJiggler, object: self.isJigglerActive)
    }

    func quitApp() {
        NSApp.terminate(nil)
    }

    private func setupKeyboardShortcut() {
        guard Settings.shared.enableKeyboardShortcut else { return }

        let keyMask: NSEvent.ModifierFlags = [.control, .option]

        self.keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 38,
               event.modifierFlags.contains(keyMask)
            {
                Task { @MainActor in
                    self?.toggleJiggler()
                }
            }
        }
    }
}

// MARK: - Menu Bar View

struct MenuBarView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @ObservedObject var settings = Settings.shared
    @ObservedObject var jiggler = JigglerController.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header with toggle
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: self.settings.menuBarIconStyle.systemImage)
                        .font(.system(size: 18))
                        .foregroundColor(self.jiggler.isActive ? .green : .primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mouse Jiggler")
                            .font(.system(size: 15, weight: .semibold))
                        Text(self.jiggler.isActive ? "Active" : "Inactive")
                            .font(.system(size: 12))
                            .foregroundColor(self.jiggler.isActive ? .green : .secondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Text("⌃⌥J")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)

                    Toggle("", isOn: Binding(
                        get: { self.jiggler.isActive },
                        set: { _ in self.appDelegate.toggleJiggler() }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .labelsHidden()
                    .scaleEffect(0.9)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    // Timing Section
                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Timing")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            HStack {
                                Text("Start After")
                                    .font(.system(size: 14))
                                Spacer()
                                TimePicker(
                                    value: self.$settings.idleThresholdMinutes,
                                    range: [10, 30, 60, 120, 300, 600],
                                    unit: "sec"
                                )
                            }

                            HStack {
                                Text("Move Every")
                                    .font(.system(size: 14))
                                Spacer()
                                TimePicker(
                                    value: self.$settings.moveIntervalSeconds,
                                    range: [5, 10, 30, 60],
                                    unit: "sec"
                                )
                            }
                        }
                    }

                    // Icon Style Section
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Menu Bar Icon")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                            ], spacing: 8) {
                                ForEach(MenuBarIconStyle.allCases) { style in
                                    IconButton(
                                        style: style,
                                        isSelected: self.settings.menuBarIconStyle == style
                                    ) {
                                        self.settings.menuBarIconStyle = style
                                    }
                                }
                            }
                        }
                    }

                    // Options Section
                    Card {
                        VStack(spacing: 0) {
                            ToggleRow(title: "Show Notifications", isOn: self.$settings.showNotifications)
                            Divider().padding(.leading, 28)
                            ToggleRow(title: "Launch at Login", isOn: self.$settings.launchAtLogin)
                        }
                    }

                    // Status Card
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Status")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            HStack(spacing: 20) {
                                StatItem(
                                    icon: "clock",
                                    value: self.jiggler.formattedIdleTime,
                                    label: "Idle Time"
                                )
                                StatItem(
                                    icon: "cursorarrow",
                                    value: self.jiggler.formattedLastJiggleTime,
                                    label: "Last Move"
                                )
                            }
                        }
                    }

                    Spacer(minLength: 6)

                    // Quit Button
                    Button(action: {
                        self.appDelegate.quitApp()
                    }) {
                        Text("Quit")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.12))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Text("Mouse Jiggler v1.0")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(12)
            }
        }
        .frame(width: 340, height: 420)
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let style: MenuBarIconStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            VStack(spacing: 4) {
                Image(systemName: self.style.systemImage)
                    .font(.system(size: 20))
                    .frame(height: 24)
                Text(self.style.displayName)
                    .font(.system(size: 10))
            }
            .foregroundColor(self.isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(self.isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Time Picker

struct TimePicker: View {
    @Binding var value: Double
    let range: [Int]
    let unit: String

    var body: some View {
        Menu {
            ForEach(self.range, id: \.self) { seconds in
                Button(self.formatTime(seconds)) {
                    self.value = Double(seconds) / 60.0
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(self.formatTime(Int(self.value * 60)))
                    .font(.system(size: 13, weight: .medium))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue)
            .cornerRadius(6)
        }
        .menuStyle(BorderlessButtonMenuStyle())
    }

    private func formatTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            return "\(seconds / 60) min"
        }
        return "\(seconds) sec"
    }
}

// MARK: - Card Component

struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        self.content
            .padding(12)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)
    }
}

// MARK: - Toggle Row

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(self.title)
                .font(.system(size: 14))
            Spacer()
            Toggle("", isOn: self.$isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .labelsHidden()
                .scaleEffect(0.85)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: self.icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(self.value)
                    .font(.system(size: 13, weight: .medium))
                Text(self.label)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let toggleJiggler = Notification.Name("toggleJiggler")
}
