import Foundation
import IOKit

/// Monitors system idle time using IOKit
actor IdleMonitor {
    
    /// Returns an async stream of idle time updates
    func idleTimeStream() -> AsyncStream<TimeInterval> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    let idleTime = self.getIdleTime()
                    continuation.yield(idleTime)
                    try? await Task.sleep(for: .seconds(1))
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    /// Get current idle time in seconds
    private func getIdleTime() -> TimeInterval {
        var idleTime: TimeInterval = 0
        
        // Create matching dictionary for IOHIDSystem
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOHIDSystem")
        )
        
        guard service != 0 else {
            print("[IdleMonitor] Failed to get IOHIDSystem service")
            return 0
        }
        
        defer {
            IOObjectRelease(service)
        }
        
        // Create property key for HIDIdleTime
        guard let propertyKey = "HIDIdleTime" as CFString? else {
            return 0
        }
        
        // Get the property
        if let property = IORegistryEntryCreateCFProperty(
            service,
            propertyKey,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() {
            
            // Handle different numeric types
            if let number = property as? NSNumber {
                let nanoseconds: UInt64 = number.uint64Value
                
                // Check if value is in nanoseconds (very large number) or already in seconds
                if nanoseconds > 1_000_000_000 {
                    // Convert nanoseconds to seconds
                    idleTime = Double(nanoseconds) / 1_000_000_000.0
                } else {
                    idleTime = Double(nanoseconds)
                }
            }
        }
        
        return idleTime
    }
}
