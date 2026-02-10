import Foundation
import Combine

/// Main controller that manages the jiggler state and coordination
@MainActor
final class JigglerController: ObservableObject {
    // MARK: - Published States
    @Published var isActive: Bool = false
    @Published var idleTime: TimeInterval = 0
    @Published var lastJiggleTime: Date?
    
    // MARK: - Constants
    private let idleThreshold: TimeInterval = 30  // 30 seconds
    private let jiggleInterval: TimeInterval = 10      // 10 seconds
    
    // MARK: - Dependencies
    private let idleMonitor = IdleMonitor()
    private let mouseController = MouseController()
    
    // MARK: - Internal State
    private var timer: Timer?
    private var state: JigglerState = .idle
    private var cancellables = Set<AnyCancellable>()
    
    enum JigglerState {
        case idle           // Not active, monitoring
        case monitoring     // Active, waiting for idle threshold
        case jiggling       // Active and jiggling
    }
    
    // MARK: - Computed Properties
    var formattedIdleTime: String {
        let minutes = Int(idleTime) / 60
        let seconds = Int(idleTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedLastJiggleTime: String {
        guard let lastTime = lastJiggleTime else {
            return "Never"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastTime, relativeTo: Date())
    }
    
    // MARK: - Initialization
    init() {
        setupIdleMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Public Methods
    func toggle() {
        if isActive {
            stop()
        } else {
            start()
        }
    }
    
    func start() {
        isActive = true
        state = .monitoring
        startTimer()
        print("[Jiggler] Started - monitoring for idle time")
    }
    
    func stop() {
        isActive = false
        state = .idle
        stopTimer()
        print("[Jiggler] Stopped")
    }
    
    // MARK: - Private Methods
    private func setupIdleMonitoring() {
        Task {
            for await newIdleTime in await idleMonitor.idleTimeStream() {
                self.idleTime = newIdleTime
                
                guard self.isActive else { continue }
                
                switch self.state {
                case .monitoring:
                    if newIdleTime >= self.idleThreshold {
                        print("[Jiggler] Idle threshold reached, starting jiggle mode")
                        self.state = .jiggling
                        self.performJiggle()
                    }
                    
                case .jiggling:
                    // If user becomes active, go back to monitoring
                    if newIdleTime < 3 {  // Less than 3 seconds = user is active
                        print("[Jiggler] User is active, pausing jiggle mode")
                        self.state = .monitoring
                    }
                    
                case .idle:
                    break
                }
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        // Only jiggle if we're in jiggling state and enough time has passed
        guard state == .jiggling else { return }
        
        let timeSinceLastJiggle = Date().timeIntervalSince(lastJiggleTime ?? .distantPast)
        if timeSinceLastJiggle >= jiggleInterval {
            performJiggle()
        }
    }
    
    private func performJiggle() {
        Task {
            await mouseController.jiggle()
            lastJiggleTime = Date()
            print("[Jiggler] Mouse jiggled at \(Date())")
        }
    }
}
