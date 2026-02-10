import SwiftUI

extension Notification.Name {
    static let toggleJiggler = Notification.Name("toggleJiggler")
}

@main
struct MouseMoverApp: App {
    @StateObject private var jiggler = JigglerController.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(jiggler)
        } label: {
            let style = Settings.shared.menuBarIconStyle
            Image(systemName: style.systemImage)
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarContent: View {
    @EnvironmentObject var jiggler: JigglerController
    @ObservedObject var settings = Settings.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header with toggle
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: settings.menuBarIconStyle.systemImage)
                        .font(.system(size: 18))
                        .foregroundColor(jiggler.isActive ? .green : .primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mouse Mover")
                            .font(.system(size: 15, weight: .semibold))
                        Text(jiggler.isActive ? "Active" : "Inactive")
                            .font(.system(size: 12))
                            .foregroundColor(jiggler.isActive ? .green : .secondary)
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
                        get: { jiggler.isActive },
                        set: { _ in jiggler.toggle() }
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
                                    value: $settings.idleThresholdMinutes,
                                    range: [10, 30, 60, 120, 300, 600],
                                    unit: "sec"
                                )
                            }

                            HStack {
                                Text("Move Every")
                                    .font(.system(size: 14))
                                Spacer()
                                TimePicker(
                                    value: $settings.moveIntervalSeconds,
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
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(MenuBarIconStyle.allCases) { style in
                                    IconButton(
                                        style: style,
                                        isSelected: settings.menuBarIconStyle == style
                                    ) {
                                        settings.menuBarIconStyle = style
                                    }
                                }
                            }
                        }
                    }

                    // Options Section
                    Card {
                        VStack(spacing: 0) {
                            ToggleRow(title: "Show Notifications", isOn: $settings.showNotifications)
                            Divider().padding(.leading, 28)
                            ToggleRow(title: "Launch at Login", isOn: $settings.launchAtLogin)
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
                                    value: jiggler.formattedIdleTime,
                                    label: "Idle Time"
                                )
                                StatItem(
                                    icon: "cursorarrow",
                                    value: jiggler.formattedLastJiggleTime,
                                    label: "Last Move"
                                )
                            }
                        }
                    }

                    Spacer(minLength: 6)

                    // Quit Button
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(8)
                    .buttonStyle(.plain)

                    Text("Mouse Mover v1.0")
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
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: style.systemImage)
                    .font(.system(size: 20))
                    .frame(height: 24)
                Text(style.displayName)
                    .font(.system(size: 10))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
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
            ForEach(range, id: \.self) { seconds in
                Button(formatTime(seconds)) {
                    value = Double(seconds) / 60.0
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(formatTime(Int(value * 60)))
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
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
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
            Text(title)
                .font(.system(size: 14))
            Spacer()
            Toggle("", isOn: $isOn)
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
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
}
