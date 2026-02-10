import Foundation
import CoreGraphics
import AppKit

/// Controls mouse cursor movement - slowly moves to random positions on screen
actor MouseController {
    
    private var isMoving = false
    
    // Movement animation settings
    private let moveDuration: TimeInterval = 0.5  // How long each move takes
    private let stepsPerMove = 20                  // Number of steps for smooth movement
    
    /// Perform a smooth move to a random position on screen
    func jiggle() {
        guard !isMoving else {
            print("[MouseController] Already moving, skipping")
            return
        }
        
        guard let screenBounds = getScreenBounds() else {
            print("[MouseController] Could not get screen bounds")
            return
        }
        
        // Get current position as starting point
        guard let startPos = getCurrentMousePosition() else {
            print("[MouseController] Could not get current mouse position")
            return
        }
        
        // Pick a random target position on screen (with padding from edges)
        let padding: CGFloat = 50
        let targetPos = CGPoint(
            x: CGFloat.random(in: padding...(screenBounds.width - padding)),
            y: CGFloat.random(in: padding...(screenBounds.height - padding))
        )
        
        isMoving = true
        
        print("[MouseController] Moving from (\(Int(startPos.x)), \(Int(startPos.y))) to (\(Int(targetPos.x)), \(Int(targetPos.y)))")
        
        // Perform animated movement
        Task {
            await animateMovement(from: startPos, to: targetPos)
            isMoving = false
            print("[MouseController] Arrived at (\(Int(targetPos.x)), \(Int(targetPos.y)))")
        }
    }
    
    /// Animate mouse movement from start to end position
    private func animateMovement(from start: CGPoint, to end: CGPoint) async {
        let stepDuration = moveDuration / Double(stepsPerMove)
        
        for step in 0...stepsPerMove {
            let progress = Double(step) / Double(stepsPerMove)
            // Use ease-in-out curve for natural movement
            let easedProgress = easeInOut(progress)
            
            let currentX = start.x + (end.x - start.x) * CGFloat(easedProgress)
            let currentY = start.y + (end.y - start.y) * CGFloat(easedProgress)
            
            moveMouse(to: CGPoint(x: currentX, y: currentY))
            
            // Small delay between steps
            try? await Task.sleep(for: .seconds(stepDuration))
        }
    }
    
    /// Ease-in-out curve for smooth acceleration/deceleration
    private func easeInOut(_ t: Double) -> Double {
        return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
    }
    
    /// Get current mouse position
    private func getCurrentMousePosition() -> CGPoint? {
        let event = CGEvent(source: nil)
        return event?.location
    }
    
    /// Move mouse to specific position immediately
    private func moveMouse(to point: CGPoint) {
        CGWarpMouseCursorPosition(point)
    }
    
    /// Get main screen bounds
    private func getScreenBounds() -> CGRect? {
        return NSScreen.main?.frame
    }
}
