import Foundation
import Combine
import CoreGraphics

/// Main controller that manages the jiggler state and coordination
@MainActor
final class JigglerController: ObservableObject {
    // MARK: - Published States
    @Published var isActive: Bool = false
    @Published var idleTime: TimeInterval = 0
    @Published var lastJiggleTime: Date?
    
    // MARK: - Constants
    private let idleThreshold: TimeInterval = 30       // 30 seconds
    private let jiggleInterval: TimeInterval = 10      // 10 seconds
    private let positionCheckThreshold: CGFloat = 5    // Min pixels moved to count as activity
    
    // MARK: - Dependencies
    private let idleMonitor = IdleMonitor()
    private let mouseController = MouseController()
    
    // MARK: - Internal State
    private var timer: Timer?
    private var state: JigglerState = .idle
    private var lastMousePosition: CGPoint?
    private var timeMouseHasBeenStill: TimeInterval = 0
    private var isUserActivelyMovingMouse = false
    private var lastJiggleCompletionTime: Date?
    
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
        lastMousePosition = getCurrentMousePosition()
        timeMouseHasBeenStill = 0
        isUserActivelyMovingMouse = false
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
        guard isActive else { return }
        
        // Check if user is actively moving the mouse by tracking position changes
        checkMouseActivity()
        
        switch state {
        case .monitoring:
            // Only start jiggling if:
            // 1. System reports idle time >= threshold
            // 2. Mouse has been still for >= threshold
            // 3. User is not actively moving mouse
            if idleTime >= idleThreshold && 
               timeMouseHasBeenStill >= idleThreshold &&
               !isUserActivelyMovingMouse {
                print("[Jiggler] Idle threshold reached (system: \(Int(idleTime))s, still: \(Int(timeMouseHasBeenStill))s), starting jiggle mode")
                state = .jiggling
                performJiggle()
            }
            
        case .jiggling:
            // Stop jiggling if user becomes active
            // User is active if system idle time drops below 2 seconds
            // We ignore isUserActivelyMovingMouse here because our own jiggle sets it to true
            if idleTime < 2 {
                print("[Jiggler] User is active (system idle: \(Int(idleTime))s), pausing jiggle mode")
                state = .monitoring
                timeMouseHasBeenStill = idleTime
            } else {
                // Continue jiggling if enough time has passed since last jiggle
                let timeSinceLastJiggle = Date().timeIntervalSince(lastJiggleTime ?? .distantPast)
                if timeSinceLastJiggle >= jiggleInterval {
                    performJiggle()
                }
            }
            
        case .idle:
            break
        }
    }
    
    /// Check if user is actively moving the mouse by comparing positions
    private func checkMouseActivity() {
        guard let currentPos = getCurrentMousePosition() else { return }
        
        // Ignore position checks right after we completed a jiggle (within 1 second)
        // This prevents us from detecting our own jiggle as user activity
        if let lastJiggle = lastJiggleCompletionTime,
           Date().timeIntervalSince(lastJiggle) < 1.0 {
            lastMousePosition = currentPos
            return
        }
        
        if let lastPos = lastMousePosition {
            let distance = hypot(currentPos.x - lastPos.x, currentPos.y - lastPos.y)
            
            if distance > positionCheckThreshold {
                // Mouse moved significantly - user is active!
                isUserActivelyMovingMouse = true
                timeMouseHasBeenStill = 0
                print("[Jiggler] Detected mouse movement: \(Int(distance))px")
            } else {
                // Mouse is still
                isUserActivelyMovingMouse = false
                timeMouseHasBeenStill += 1
            }
        }
        
        lastMousePosition = currentPos
    }
    
    private func getCurrentMousePosition() -> CGPoint? {
        let event = CGEvent(source: nil)
        return event?.location
    }
    
    private func performJiggle() {
        Task {
            lastJiggleTime = Date()
            await mouseController.jiggle()
            lastJiggleCompletionTime = Date()
            // After jiggling, update lastMousePosition to the new position
            // so we don't detect our own movement as user activity
            lastMousePosition = getCurrentMousePosition()
            print("[Jiggler] Mouse moved at \(Date())")
        }
    }
}
