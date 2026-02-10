# 🖱️ Mouse Jiggler

A macOS app that keeps your device active by gently moving the mouse cursor when you're away.

## How It Works

1. **Start** the app by clicking the "Start" button
2. The app monitors your idle time (keyboard & mouse inactivity)
3. After **5 minutes** of inactivity, the jiggler activates
4. Every **10 seconds**, it performs a tiny mouse movement
5. When you return (move mouse or type), jiggling pauses automatically

## Building

```bash
swift build
```

## Running

### Option 1: Direct from build
```bash
swift run
```

### Option 2: As an App Bundle
```bash
# Build first
swift build

# Create app bundle
mkdir -p MouseJiggler.app/Contents/MacOS
cp .build/debug/MouseJiggler MouseJiggler.app/Contents/MacOS/

# Open the app
open MouseJiggler.app
```

## Project Structure

```
Sources/MouseJiggler/
├── MouseJiggler.swift          # App entry point
├── Views/
│   └── ContentView.swift       # SwiftUI interface
├── Controllers/
│   └── JigglerController.swift # Main logic coordinator
└── Services/
    ├── IdleMonitor.swift       # Detects system idle time (IOKit)
    └── MouseController.swift   # Controls mouse movement (CoreGraphics)
```

## Permissions

The app requires **Accessibility permissions** to control the mouse cursor. You'll be prompted on first run.

To grant permissions manually:
1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Add and enable **MouseJiggler**

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Mouse Jiggler App                     │
├─────────────────────────────────────────────────────────┤
│  UI Layer (SwiftUI)                                     │
│  ├── Toggle Button (Active/Inactive)                    │
│  └── Status Indicator                                   │
├─────────────────────────────────────────────────────────┤
│  Core Logic                                             │
│  ├── Idle Monitor (tracks last mouse/keyboard activity) │
│  ├── State Machine: IDLE_CHECK → JIGGLE_MODE            │
│  └── Mouse Controller (random cursor movement)          │
├─────────────────────────────────────────────────────────┤
│  macOS APIs                                             │
│  ├── IOKit (IOHIDSystem) - idle time detection          │
│  └── CoreGraphics (CGWarpMouseCursorPosition)           │
└─────────────────────────────────────────────────────────┘
```

## Requirements

- macOS 13.0+
- Swift 5.9+
