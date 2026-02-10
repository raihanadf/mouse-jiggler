import Foundation

/// Menu bar icon styles
enum MenuBarIconStyle: String, CaseIterable, Identifiable {
    case mouse
    case cat
    case dog
    case ghost
    case robot
    case gamecontroller
    case flame
    case bolt

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .mouse: "cursorarrow.click.2"
        case .cat: "cat.fill"
        case .dog: "dog.fill"
        case .ghost: "eyes"
        case .robot: "cpu.fill"
        case .gamecontroller: "gamecontroller.fill"
        case .flame: "flame.fill"
        case .bolt: "bolt.fill"
        }
    }

    var displayName: String {
        switch self {
        case .mouse: "Mouse"
        case .cat: "Cat"
        case .dog: "Dog"
        case .ghost: "Ghost"
        case .robot: "Robot"
        case .gamecontroller: "Game"
        case .flame: "Fire"
        case .bolt: "Bolt"
        }
    }
}

/// App settings managed via UserDefaults
@MainActor
final class Settings: ObservableObject {
    static let shared = Settings()

    private let defaults = UserDefaults.standard

    // MARK: - Published Settings

    @Published var idleThresholdMinutes: Double {
        didSet { self.defaults.set(self.idleThresholdMinutes, forKey: Keys.idleThresholdMinutes) }
    }

    @Published var moveIntervalSeconds: Double {
        didSet { self.defaults.set(self.moveIntervalSeconds, forKey: Keys.moveIntervalSeconds) }
    }

    @Published var launchAtLogin: Bool {
        didSet { self.defaults.set(self.launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var showNotifications: Bool {
        didSet { self.defaults.set(self.showNotifications, forKey: Keys.showNotifications) }
    }

    @Published var enableKeyboardShortcut: Bool {
        didSet { self.defaults.set(self.enableKeyboardShortcut, forKey: Keys.enableKeyboardShortcut) }
    }

    @Published var menuBarIconStyle: MenuBarIconStyle {
        didSet {
            self.defaults.set(self.menuBarIconStyle.rawValue, forKey: Keys.menuBarIconStyle)
            NotificationCenter.default.post(name: .menuBarIconChanged, object: nil)
        }
    }

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let idleThresholdMinutes = "idleThresholdMinutes"
        static let moveIntervalSeconds = "moveIntervalSeconds"
        static let launchAtLogin = "launchAtLogin"
        static let showNotifications = "showNotifications"
        static let enableKeyboardShortcut = "enableKeyboardShortcut"
        static let menuBarIconStyle = "menuBarIconStyle"
    }

    // MARK: - Computed Properties

    var idleThresholdSeconds: TimeInterval {
        self.idleThresholdMinutes * 60
    }

    // MARK: - Initialization

    private init() {
        let defaults: [String: Any] = [
            Keys.idleThresholdMinutes: 0.5, // 30 seconds
            Keys.moveIntervalSeconds: 10.0,
            Keys.launchAtLogin: false,
            Keys.showNotifications: true,
            Keys.enableKeyboardShortcut: true,
            Keys.menuBarIconStyle: MenuBarIconStyle.mouse.rawValue,
        ]
        self.defaults.register(defaults: defaults)

        self.idleThresholdMinutes = self.defaults.double(forKey: Keys.idleThresholdMinutes)
        self.moveIntervalSeconds = self.defaults.double(forKey: Keys.moveIntervalSeconds)
        self.launchAtLogin = self.defaults.bool(forKey: Keys.launchAtLogin)
        self.showNotifications = self.defaults.bool(forKey: Keys.showNotifications)
        self.enableKeyboardShortcut = self.defaults.bool(forKey: Keys.enableKeyboardShortcut)

        if let rawValue = self.defaults.string(forKey: Keys.menuBarIconStyle),
           let style = MenuBarIconStyle(rawValue: rawValue)
        {
            self.menuBarIconStyle = style
        } else {
            self.menuBarIconStyle = .mouse
        }
    }

    // MARK: - Reset

    func resetToDefaults() {
        self.idleThresholdMinutes = 0.5
        self.moveIntervalSeconds = 10.0
        self.launchAtLogin = false
        self.showNotifications = true
        self.enableKeyboardShortcut = true
        self.menuBarIconStyle = .mouse
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let menuBarIconChanged = Notification.Name("menuBarIconChanged")
}
